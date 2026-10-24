#!/bin/bash
# =============================================================================
# ETL2miaoda.sh — Got SQL 导出 → data/ CSV → 导入妙搭库（dev/online）全链批处理
#
# 用法:
#   ./ETL2miaoda.sh                                  # 默认：近16天(止=昨天)，导 dev
#   ./ETL2miaoda.sh --start-date 2026-10-08 --end-date 2026-10-23 --env dev
#   ./ETL2miaoda.sh --env online                     # online 需门3人工确认（交互 YES 或 ONLINE_CONFIRM=1）
#   ./ETL2miaoda.sh --only ads_sku_daily             # 单表快跑（跳过其余表，导出与导入都只处理它）
#   ./ETL2miaoda.sh --skip-export                    # 不重导 CSV，直接用现有 data/ 灌库
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
# =============================================================================
set -uo pipefail

AUTOMATION=/home/ray/Documents/RecentWorks/Automation
BID=/home/ray/Documents/RecentWorks/BIDashboard
IMPORT="$BID/scripts/import_data2miaoda.sh"
DATA_DIR="$BID/data"
LOG_DIR="$BID/logs/etl"
mkdir -p "$LOG_DIR"

END_DATE=$(date -d 'yesterday' +%F)
START_DATE=$(date -d "$END_DATE -15 day" +%F)   # 默认近 16 天（止=昨天，T+1 产出）
ENV=dev
ONLY=""
SKIP_EXPORT=0

while [ $# -gt 0 ]; do
  case "$1" in
    --start-date) START_DATE="${2:?}"; shift 2;;
    --end-date)   END_DATE="${2:?}"; shift 2;;
    --env)        ENV="${2:?}"; shift 2;;
    --only)       ONLY="${2:?}"; shift 2;;
    --skip-export) SKIP_EXPORT=1; shift;;
    -h|--help)    grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
    *) echo "未知参数: $1（-h 看用法）" >&2; exit 2;;
  esac
done
case "$ENV" in dev|online) : ;; *) echo "--env 仅支持 dev|online" >&2; exit 2;; esac
[[ "$START_DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ && "$END_DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || { echo "日期须 YYYY-MM-DD" >&2; exit 2; }
[ "$START_DATE" \> "$END_DATE" ] && { echo "start-date 不能晚于 end-date" >&2; exit 2; }

# ── 门3：online 显式确认（与导入脚本硬门同语义，双重闸） ─────────────────────
if [ "$ENV" = "online" ] && [ "${ONLINE_CONFIRM:-0}" != "1" ]; then
  echo "⚠️  目标是【online 生产库】：将按 dt 范围[$START_DATE~$END_DATE]先删后插 12 表。"
  read -r -p "确认请输入大写 YES（其他任意输入中止）: " ans
  [ "$ans" = "YES" ] || { echo "已中止。可设 ONLINE_CONFIRM=1 免交互。"; exit 1; }
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
declare -a NAME RESULT DETAIL
n_ok=0; n_fail=0; n_skip=0

record() { NAME+=("$1"); RESULT+=("$2"); DETAIL+=("$3"); }

# ── ① 导出 ──────────────────────────────────────────────────────────────────
if [ "$SKIP_EXPORT" = "0" ]; then
  [ -d "$AUTOMATION/Got" ] || { echo "缺少 $AUTOMATION/Got" >&2; exit 1; }
  cd "$AUTOMATION"
  for f in Got/*.sql; do
    base=$(basename "$f" .sql)
    [ -n "$ONLY" ] && [ "$base" != "$ONLY" ] && continue
    echo "▶ 导出 $base ($START_DATE~$END_DATE) $(date +%H:%M:%S)"
    if ./scripts/batch_export_sql.sh --sql-file "$f" --start-date "$START_DATE" --end-date "$END_DATE" --output-dir ./apaas >>"$RUN_LOG" 2>&1; then
      echo "  ✓ $base 导出 ok"
    else
      echo "  ✗ $base 导出失败（详见 $RUN_LOG）"
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
  [ -n "$ONLY" ] && [ "${base%.csv}" != "$ONLY" ] && continue
  mv -f "$f" "$DATA_DIR/" && moved=$((moved+1))
done
echo "▶ 已搬运 $moved 个 CSV → data/ $(date +%H:%M:%S)"

# ── ③ 导入 ──────────────────────────────────────────────────────────────────
cd "$BID"
for f in "$DATA_DIR"/*.csv; do
  [ -e "$f" ] || continue
  base=$(basename "$f" .csv)
  [ -n "$ONLY" ] && [ "$base" != "$ONLY" ] && continue
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
  if out=$(ONLINE_CONFIRM="${ONLINE_CONFIRM:-0}" "$IMPORT" --csv "$f" --table "$tbl" --env "$ENV" --mode clear --int-float-fix 2>&1) && echo "$out" | tee "$file_log" >/dev/null; then
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
for i in "${!NAME[@]}"; do printf '%-42s %-12s %s\n' "${NAME[$i]}" "${RESULT[$i]}" "${DETAIL[$i]}"; done
[ "${#NAME[@]}" -eq 0 ] && echo "(无处理项)"
echo "──────────────────────────────────────────────"
echo "OK=$n_ok FAIL=$n_fail · 总日志: $RUN_LOG"
[ "$n_fail" -eq 0 ] || exit 1
