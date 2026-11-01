#!/bin/bash
# =============================================================================
# ETL2miaoda.sh — Got SQL 导出 → data/ CSV → 导入妙搭库（dev/online）全链批处理
#
# 用法:
#   ./ETL2miaoda.sh                                  # 默认：近16天(止=昨天)，导 dev
#   ./ETL2miaoda.sh --start-date 2026-10-08 --end-date 2026-10-23 --env dev
#   ./ETL2miaoda.sh --env online                     # online 需门3人工确认（交互 YES 或 ONLINE_CONFIRM=1）
#   ./ETL2miaoda.sh --only ads_sku_daily             # 限定表快跑（逗号分隔多表：--only a,b,c）
#   ./ETL2miaoda.sh --skip-export                    # 不跑导出，直接用现有 data/ CSV 灌库
#   ./ETL2miaoda.sh --retry-failed                   # 按上次运行的失败清单（EXPORT_FAIL/IMPORT_SKIPPED/FAIL）
#                                                    #   自动组成 --only 集合重跑全链（网络抖动续传场景）
#   组合示例：导出挂了后续传两张表 →  ./ETL2miaoda.sh --only ads_merchant_category_daily,ads_sku_county_daily
#             只想重灌 distribute 一张 → ./ETL2miaoda.sh --skip-export --only ads_cat4_mct_distribute_daily
#
# 三段流程（对齐 2026-10-24 人工推送方案）:
#   ① 导出: Automation/scripts/batch_export_sql.sh 逐个跑 Got/*.sql → apaas/*.csv
#   ② 搬运: apaas/*.csv 覆盖移动到 BIDashboard/data/
#   ③ 导入: scripts/import_data2miaoda.sh --mode clear --int-float-fix（列核对/双判重/
#           按 dt 范围先删后插幂等，online 受 ONLINE_CONFIRM 门约束）
#
# 表名映射（文件名≠表名的两张县表，与导入脚本约定同源）:
#   ads_category_county_daily.csv           → ads_cat4_county_daily
#   ads_merchant_category_county_daily.csv  → ads_mct_cat4_county_daily
#   其余同名
#
# 已知边界（重要）:
#   - clear 幂等只覆盖【本批 CSV 自带的 dt 范围】；库内早于起始日的历史行不会被删。
#     上游缩窄范围（如 Top 表只导最近 N 天）时旧行会残留 → 长窗口图表混旧口径。
#     需要"整表与 CSV 完全一致"时，先人工核对后手动 DELETE 范围外的 dt（脚本不代做删数）。
#   - 逐文件独立成败：单表失败不中断其余，最后汇总表格结论并以非零码退出。
#   - biz_* 目标表不在本链（源为飞书多维表格，非 Got SQL）。
#
# 网络抖动自愈（2026-10-31，当日 dev 实测 3 起瞬断均需人工重跑）:
#   - 导出失败自动重试 1 次（batch_export_sql.sh 断点续传，重试不重拉已完成批次）
#   - 导入仅【网络类】失败（type:"network"/timeout 特征）自动重试 1 次（clear 幂等）；
#     数据类失败（列核对/判重/NOT NULL 空值硬门）重跑必然同败 → 立即失败交人
#   - 导入脚本内部另有：表结构拉取×3、DELETE×2、分片×2、count 校验×3 的重试
#   - 仍失败 → 汇总记 EXPORT_FAIL/FAIL，用 --retry-failed 一键续跑
# =============================================================================
set -uo pipefail

AUTOMATION=/home/ray/Documents/RecentWorks/Automation
BID=/home/ray/Documents/RecentWorks/BIDashboard
IMPORT="$BID/scripts/import_data2miaoda.sh"
DATA_DIR="$BID/data"
LOG_DIR="$BID/logs/etl"
mkdir -p "$LOG_DIR" "$DATA_DIR"

# 防并发：batch_export_sql.sh 的断点续传状态是共享文件，两个 ETL 实例同跑会互踩
exec 9>"$LOG_DIR/.etl.lock"
flock -n 9 || { echo "❌ 已有另一个 ETL 实例在运行（锁: $LOG_DIR/.etl.lock），本次中止" >&2; exit 3; }

END_DATE=$(date -d 'yesterday' +%F)
START_DATE=$(date -d "$END_DATE -15 day" +%F)   # 默认近 16 天（止=昨天，T+1 产出）
ENV=dev
ONLY=""
SKIP_EXPORT=0
RETRY_FAILED=0

while [ $# -gt 0 ]; do
  case "$1" in
    --start-date) START_DATE="${2:?}"; shift 2;;
    --end-date)   END_DATE="${2:?}"; shift 2;;
    --env)        ENV="${2:?}"; shift 2;;
    --only)       ONLY="${2:?}"; shift 2;;
    --skip-export) SKIP_EXPORT=1; shift;;
    --retry-failed) RETRY_FAILED=1; shift;;
    -h|--help)    grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
    *) echo "未知参数: $1（-h 看用法）" >&2; exit 2;;
  esac
done
# --only 匹配：逗号/空格分隔多表（归一化后精确匹配 base 名）
only_has() { [[ ",${ONLY// /}," == *",$1,"* ]]; }

case "$ENV" in dev|online) : ;; *) echo "--env 仅支持 dev|online" >&2; exit 2;; esac
[[ "$START_DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ && "$END_DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || { echo "日期须 YYYY-MM-DD" >&2; exit 2; }
[ "$START_DATE" \> "$END_DATE" ] && { echo "start-date 不能晚于 end-date" >&2; exit 2; }

# ── --retry-failed：从上次同环境汇总提取失败清单作为 --only ─────────────────
SUMMARY="$LOG_DIR/last_summary_$ENV.txt"
if [ "$RETRY_FAILED" = "1" ]; then
  [ -f "$SUMMARY" ] || { echo "无 $SUMMARY 可解析（先完成一次常规运行）" >&2; exit 2; }
  FAILED=$(awk '$2=="EXPORT_FAIL"||$2=="IMPORT_SKIPPED"||$2=="FAIL"{print $1}' "$SUMMARY" | sort -u | paste -sd, -)
  [ -n "$FAILED" ] || { echo "上次运行无失败项，无需重试。"; exit 0; }
  [ -n "$ONLY" ] && { echo "--retry-failed 与 --only 互斥（retry 会自动组清单）" >&2; exit 2; }
  ONLY="$FAILED"
  echo "↻ 重试失败表：$ONLY"
  if [ "$SKIP_EXPORT" = "1" ] && grep -qE " (EXPORT_FAIL|IMPORT_SKIPPED) " "$SUMMARY"; then
    echo "   ⚠ 清单含导出失败表但当前为 --skip-export：这些表将用 data/ 现有（可能陈旧）CSV 重灌；"
    echo "     如需新数据请去掉 --skip-export 让导出重跑（工具支持断点续传）。"
  fi
fi

# ── 门3：online 显式确认（与导入脚本硬门同语义，双重闸） ─────────────────────
if [ "$ENV" = "online" ] && [ "${ONLINE_CONFIRM:-0}" != "1" ]; then
  echo "⚠️  目标是【online 生产库】：将按 dt 范围[$START_DATE~$END_DATE]先删后插（Got 全量表或 --only 限定）。"
  read -r -p "确认请输入大写 YES（其他任意输入中止）: " ans
  [ "$ans" = "YES" ] || { echo "已中止。可设 ONLINE_CONFIRM=1 免交互。"; exit 1; }
  # 修复（2026-10-26 实战）：外闸 YES 通过后传导确认给内层导入脚本同名门，
  # 否则每表都被内层 ONLINE_CONFIRM 硬门拒绝（双闸自锁 bug）。
  export ONLINE_CONFIRM=1
  echo "   ✓ 门3 人工确认通过，内层导入同确认生效。"
fi

map_table() {
  case "$1" in
    ads_category_county_daily) echo ads_cat4_county_daily;;
    ads_merchant_category_county_daily) echo ads_mct_cat4_county_daily;;
    *) echo "$1";;
  esac
}

RUN_LOG="$LOG_DIR/etl_$(date +%Y%m%d_%H%M%S)_$ENV.log"
RUN_START=$(date +%s)
declare -A EXPORT_FAILED=()
# 注意：必须用 () 显式赋值初始化。仅 declare -a 时数组处于"已声明未设置"态，
# set -u 下 ${#NAME[@]} 直接炸 unbound，而脚本无 -e → 报错后继续跑假绿退出（2026-10-26 实测）。
NAME=(); RESULT=(); DETAIL=()
n_ok=0; n_fail=0

record() { NAME+=("$1"); RESULT+=("$2"); DETAIL+=("$3"); }

# ── ① 导出 ──────────────────────────────────────────────────────────────────
if [ "$SKIP_EXPORT" = "0" ]; then
  [ -d "$AUTOMATION/Got" ] || { echo "缺少 $AUTOMATION/Got" >&2; exit 1; }
  cd "$AUTOMATION"
  for f in Got/*.sql; do
    base=$(basename "$f" .sql)
    [ -n "$ONLY" ] && ! only_has "$base" && continue
    echo "▶ 导出 $base ($START_DATE~$END_DATE) $(date +%H:%M:%S)"
    # 网络抖动自动重试 1 次（2026-10-31 dev 实测：MaxCompute endpoint 连接超时挂 2 表，
    # 人工原样重跑即成功）；batch_export_sql.sh 自带断点续传，重试从断点续跑不重拉已完成批次
    exp_ok=0
    for etry in 1 2; do
      if ./scripts/batch_export_sql.sh --sql-file "$f" --start-date "$START_DATE" --end-date "$END_DATE" --output-dir ./apaas >>"$RUN_LOG" 2>&1; then
        exp_ok=1; break
      fi
      [ "$etry" = 1 ] && { echo "  ↻ $base 导出失败，10s 后重试（断点续传）$(date +%H:%M:%S)"; sleep 10; }
    done
    if [ "$exp_ok" = 1 ]; then
      echo "  ✓ $base 导出 ok"
    else
      echo "  ✗ $base 导出失败（重试后仍失败，详见 $RUN_LOG）"
      record "$base" "EXPORT_FAIL" "见 $RUN_LOG"
      EXPORT_FAILED[$base]=1
    fi
    sleep 5
  done
fi

# ── ② 搬运 ──────────────────────────────────────────────────────────────────
moved=0
for f in "$AUTOMATION"/apaas/*.csv; do
  [ -e "$f" ] || continue
  base=$(basename "$f")
  [ -n "$ONLY" ] && ! only_has "${base%.csv}" && continue
  mv -f "$f" "$DATA_DIR/" && moved=$((moved+1))
done
echo "▶ 已搬运 $moved 个 CSV → data/ $(date +%H:%M:%S)"

# ── ③ 导入 ──────────────────────────────────────────────────────────────────
cd "$BID"
for f in "$DATA_DIR"/*.csv; do
  [ -e "$f" ] || continue
  base=$(basename "$f" .csv)
  [ -n "$ONLY" ] && ! only_has "$base" && continue
  # 仅处理本 ETL 覆盖的 12 表（data/ 里若有杂项文件跳过）
  [ -e "$AUTOMATION/Got/$base.sql" ] || { echo "· 跳过非 Got 表源文件: $base"; continue; }
  # 防陈旧数据两道闸（2026-10-25 实战事故：导出失败后旧 CSV 被静默重灌并报 OK）：
  # ① 本轮导出失败的表拒绝导入；② CSV mtime 早于本轮启动=非本轮产物，跳过（--skip-export 明示除外）
  if [ -n "${EXPORT_FAILED[$base]:-}" ]; then
    echo "  ⏭ $base 跳过导入：本轮导出失败，拒绝复用陈旧 CSV"
    record "$base" "IMPORT_SKIPPED" "导出失败，陈旧 CSV 未灌"
    n_fail=$((n_fail+1)); continue
  fi
  if [ "$SKIP_EXPORT" = "0" ] && [ "$(stat -c %Y "$f")" -lt "$RUN_START" ]; then
    echo "  ⏭ $base 跳过导入：CSV 非本轮产物（mtime 早于启动时刻）"
    record "$base" "IMPORT_SKIPPED" "陈旧文件未灌；如需重灌用 --skip-export --only $base"
    n_fail=$((n_fail+1)); continue
  fi
  tbl=$(map_table "$base")
  echo "▶ 导入 $base → $tbl (env=$ENV, mode=clear) $(date +%H:%M:%S)"
  file_log="$LOG_DIR/${base}_${ENV}_$(date +%Y%m%d_%H%M%S).log"
  # 网络类失败自动重试 1 次（2026-10-31 dev 实测：预检拉表结构 dial timeout 杀整表，人工重跑即好）。
  # 判据=lark-cli 错误 JSON 的 type:"network" 或 timeout 字样；数据类失败（硬门/判重/NOT NULL 空值）
  # 重跑必然同败，立即失败交人。clear 模式按 dt 范围幂等，整表重跑安全。
  imp_ok=0
  for itry in 1 2; do
    if out=$(ONLINE_CONFIRM="${ONLINE_CONFIRM:-0}" "$IMPORT" --csv "$f" --table "$tbl" --env "$ENV" --mode clear --int-float-fix 2>&1); then
      imp_ok=1; break
    fi
    # 判据补 context deadline exceeded（2026-10-31 中午实测：本地代理劣化时 lark-cli 报
    # type:"internal"+deadline 而非 network/timeout，旧判据漏掉导致不重试）
    if [ "$itry" = 1 ] && echo "$out" | grep -qE '"type": *"network"|timeout|context deadline exceeded'; then
      echo "$out" > "$file_log.nettry1"
      echo "  ↻ $base 网络类失败，10s 后重试导入（clear 幂等）$(date +%H:%M:%S)"
      sleep 10
      continue
    fi
    break
  done
  if [ "$imp_ok" = 1 ]; then
    echo "$out" > "$file_log"
    rows=$("$BID/.venv/bin/python" -I -c "import pyarrow.csv as c
r=c.open_csv('$f')
n=0
while True:
    try: b=r.read_next_batch()
    except StopIteration: break
    n+=b.num_rows
print(n)" 2>/dev/null || echo '?')
    echo "  ✓ $base ok (${rows} 行)"
    record "$base" "OK" "${rows} 行"
    n_ok=$((n_ok+1))
  else
    echo "$out" > "$file_log"
    echo "  ✗ $base 失败 → 日志 $file_log"
    echo "$out" | tail -6 | sed 's/^/     /'
    record "$base" "FAIL" "日志 $(basename "$file_log")"
    n_fail=$((n_fail+1))
  fi
  sleep 5
done

# ── ④ 汇总 ──────────────────────────────────────────────────────────────────
echo
echo "════════ ETL 结果汇总 · env=$ENV · dt $START_DATE~$END_DATE ════════"
printf '%-42s %-12s %s\n' "表(base)" "结果" "备注"
if [ "${#NAME[@]}" -gt 0 ]; then
  for i in "${!NAME[@]}"; do printf '%-42s %-12s %s\n' "${NAME[$i]}" "${RESULT[$i]}" "${DETAIL[$i]}"; done
else
  echo "(无处理项)"
fi
echo "──────────────────────────────────────────────"
echo "OK=$n_ok FAIL=$n_fail · 总日志: $RUN_LOG"
# 零处理 = 明显误用（--only 拼错等），以 exit 2 结束且【不覆盖】last_summary，
# 保护上次失败清单仍可被 --retry-failed 使用（2026-10-26 显式化此前隐式行为）。
[ "${#NAME[@]}" -gt 0 ] || { echo "❌ 本轮无任何表被处理（--only 拼写/Got 源/CSV 存在性三连查）；已保留上次汇总: $SUMMARY" >&2; exit 2; }
# 先写临时文件再原子替换：展开中途出错时不会把旧汇总截断成空
{ for i in "${!NAME[@]}"; do printf '%s %s %s\n' "${NAME[$i]}" "${RESULT[$i]}" "${DETAIL[$i]}"; done; } > "$SUMMARY.tmp" && mv -f "$SUMMARY.tmp" "$SUMMARY"
echo "汇总已写: $SUMMARY"
[ "$n_fail" -eq 0 ] || exit 1
