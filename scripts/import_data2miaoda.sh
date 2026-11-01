#!/bin/bash
# 通用 CSV → 应用库表导入（lark-cli），全部行为由参数控制：
#   --csv <路径>        数据文件（必需；约定放 BIDashboard/data/ 下）
#   --table <表名>      目标表（必需；表名不必等于文件名，如
#                       ads_merchant_category_county_daily.csv → ads_mct_cat4_county_daily）
#   --env <dev|online>  环境（必需；online 需另设 ONLINE_CONFIRM=1）
#   --mode <clear|append> clear=按 CSV 的 dt 范围先删后插（清空导入，幂等可重跑）
#                        append=直接追加（覆盖导入：撞唯一键由 DB 报错中止）
#   重复硬门（预检，任一 >0 即中止，不做任何自动修复）：
#     1) 整行重复：pandas df.duplicated().sum()
#     2) uk 重复：df.duplicated(subset=uk列).sum()，uk 从 +db-table-get 的 unique index 实时读取
#   --int-float-fix     唯一的值归一开关（默认关）：^-?\d+\.0+$ 形态的格（bigint 列 '12.0'、
#                       ID 列 '31860.0'）归整为整数文本；无损（数值完全相等），重复检查按归整后
#                       的值进行（与导入语义一致）
#
# Python 环境：优先用仓库根 .venv（pyenv local + requirements.txt：pyarrow 流式处理，
#   支撑数十 MB 大文件不整表载入内存）；缺 .venv 时给出构建指令并中止。
#   构建：cd BIDashboard && pyenv local 3.12.13 && python -m venv .venv \
#         && .venv/bin/pip install -r scripts/requirements.txt
#
# 硬门（不可协商）：
#   1) 列核对先行：CSV 表头出现任何表外列（疑似拼写错误/多余列）→ 立即中止并输出差异，
#      由人修正数据文件或确认表结构后重试；脚本绝不自动改名/剔列。
#   2) 表内 NOT NULL 且无默认值的列在 CSV 中缺失 → 中止。
#      2b) NOT NULL 列**值**为空（2026-10-31 前移）：脏值行曾穿透列名核对、直到分片导入
#          Row 620 才爆——彼时 clear 的 DELETE 已执行。现在 pandas 预检直接中止（零副作用），
#          报列名/空值数/首个文件行号；脚本绝不自动过滤行，修数仓 SQL 后重导。
#   3) 任一分片失败重试一次后仍失败 → 中止（clear 模式可安全重跑）。
# 网络抖动自愈（2026-10-31，当日 dev 实测 3 起瞬断全部人工重跑即好）：
#   表结构拉取重试 3 次（只读）；DELETE 重试 1 次（按 dt 范围幂等，重执行安全）；
#   分片导入重试 1 次（既有）；count 校验重试 3 次（既有）。数据类失败不在此列，立即失败。
# 大数据量：按实测字节自动切 ≤900KB 分片（lark-cli 单请求 1MB 上限），并封顶 ≤5000 行/片
#   （平台硬性限制 k_dl_4000007: Import exceeds 5000 rows limit），逐片导入。
set -euo pipefail
APP=app_17g5uw7qhs7
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PY="$ROOT/.venv/bin/python"
CSV="" TABLE="" ENV="" MODE="" FIXINT=0
while [ $# -gt 0 ]; do
  case "$1" in
    --csv) CSV="${2:?}"; shift 2;;
    --table) TABLE="${2:?}"; shift 2;;
    --env) ENV="${2:?}"; shift 2;;
    --mode) MODE="${2:?}"; shift 2;;
    --int-float-fix) FIXINT=1; shift;;
    *) echo "未知参数: $1" >&2; exit 2;;
  esac
done
[ -n "$CSV" ] && [ -n "$TABLE" ] && [ -n "$ENV" ] && [ -n "$MODE" ] || { echo "用法: $0 --csv f.csv --table 表名 --env dev|online --mode clear|append" >&2; exit 2; }
case "$MODE" in clear|append) ;; *) echo "--mode 仅支持 clear|append" >&2; exit 2;; esac
case "$ENV" in dev|online) ;; *) echo "--env 仅支持 dev|online" >&2; exit 2;; esac
[ -f "$CSV" ] || { echo "文件不存在: $CSV" >&2; exit 2; }
[ -x "$PY" ] || { echo "缺少 Python 环境：$PY 不存在。构建：cd $ROOT && pyenv local 3.12.13 && python -m venv .venv && .venv/bin/pip install -r scripts/requirements.txt" >&2; exit 2; }
"$PY" -c "import pyarrow" 2>/dev/null || { echo ".venv 缺 pyarrow：$PY -m pip install -r $ROOT/scripts/requirements.txt" >&2; exit 2; }
if [ "$ENV" = "online" ] && [ "${ONLINE_CONFIRM:-0}" != "1" ]; then
  echo "!! online 生产库操作：确认请设 ONLINE_CONFIRM=1 重跑" >&2; exit 2
fi
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

# ── 门1/门2：列核对（只读，零副作用） ─────────────────────────
# 拉表结构网络抖动重试 3 次（2026-10-31 dev 实测：单次 dial timeout 直接杀死整表导入，
# 人工重跑即成功——与 count 校验段 retry 同族修法；本步只读，重试绝对安全）
got=0
for gt in 1 2 3; do
  if lark-cli apps +db-table-get --app-id $APP --table "$TABLE" --environment "$ENV" > "$TMP/tbl.json" 2>"$TMP/tbl.err" && grep -q '"ok": true' "$TMP/tbl.json"; then
    got=1; break
  fi
  [ "$gt" -lt 3 ] && { echo "拉取表结构未成功（第 $gt/3 次，疑网络抖动），3s 后重试..."; sleep 3; }
done
[ "$got" = 1 ] || { echo "❌ 中止：拉取表结构连续 3 次失败（网络/端点异常），零副作用。最后输出:" >&2; cat "$TMP/tbl.json" "$TMP/tbl.err" >&2; exit 1; }
"$PY" -I - "$CSV" "$TMP/tbl.json" <<'PY'
import csv, json, sys
with open(sys.argv[1], newline='', encoding='utf-8-sig') as f:
    header = next(csv.reader(f))
raw = json.load(open(sys.argv[2]))
assert raw.get('ok'), '拉取表结构失败'
cols = raw['data']['table']['columns'] if 'table' in raw['data'] else raw['data']['columns']
db = {c['name'] for c in cols}
SYSTEM = {'id', '_synced_at', '_sync_batch_id'}
required = {c['name'] for c in cols if not c.get('nullable', True) and not c.get('default') and c['name'] not in SYSTEM}
csv_only = [c for c in header if c not in db]
missing_required = sorted(required - set(header))
if csv_only or missing_required:
    if csv_only:
        print(f"❌ 中止：CSV 存在表外列（疑似表头拼写错误或多余列，请修正数据文件/确认表结构）: {csv_only}", file=sys.stderr)
    if missing_required:
        print(f"❌ 中止：表内 NOT NULL 无默认列在 CSV 缺失: {missing_required}", file=sys.stderr)
    sys.exit(1)
print(f"✅ 列核对通过：CSV {len(header)} 列全部为表列；必需列齐备")
PY

# ── 预检（pandas）：行数 / dt 范围 / 重复硬门（整行 + uk，任一>0 即停） ──
# dtype=str + 关闭 NA 推断：读到什么是什么，与导入字节一致；
# --int-float-fix 开启时先归整（判重与导入语义一致）；uk 从 tbl.json 实时读取。
meta=$("$PY" -I - "$CSV" "$TMP/tbl.json" "$FIXINT" <<'PY'
import json, re, sys
import pandas as pd
path, tbljson = sys.argv[1], sys.argv[2]
fixint = sys.argv[3] == '1'
raw = json.load(open(tbljson)); assert raw.get('ok'), '表结构读取失败'
t = raw['data'].get('table', raw['data'])
uks = [i for i in t.get('indexes', []) if i.get('type') == 'unique' or i.get('name', '').startswith('uk_')]
uk = next((i['columns'] for i in uks if 'dt' in (i.get('columns') or [])), None) \
     or ((uks[0].get('columns') or []) if uks else [])
df = pd.read_csv(path, dtype=str, keep_default_na=False, na_values=[])
if fixint:
    IP = re.compile(r'^(-?\d+)\.0+$')
    df = df.apply(lambda s: s.str.replace(IP, r'\1', regex=True))
# 门2b（2026-10-31 前移）：NOT NULL 无默认列的**值**不得为空。
# 此前脏值行穿透列名核对、到分片导入才爆（Row 620 实测），彼时 clear 的 DELETE 已执行；
# 现在预检零副作用中止。绝不自动过滤行——修数仓 SQL/数据后重导。
SYSTEM = {'id', '_synced_at', '_sync_batch_id'}
cols = t['columns'] if 'columns' in t else raw['data']['columns']
required = [c['name'] for c in cols if not c.get('nullable', True) and not c.get('default') and c['name'] not in SYSTEM]
null_bad = []
for c in required:
    if c in df.columns:
        empt = df[c].str.strip() == ''
        if int(empt.sum()) > 0:
            null_bad.append((c, int(empt.sum()), int(df.index[empt][0]) + 2))  # +2=文件物理行号（表头1行+0基）
if null_bad:
    for c, n, ln in null_bad:
        print(f"❌ 中止：NOT NULL 列 '{c}' 存在 {n} 个空值（首个在文件第 {ln} 行）——数据源/数仓 SQL 修正后重导，脚本不自动过滤行", file=sys.stderr)
    sys.exit(1)
dup_full = int(df.duplicated().sum())
if uk and all(c in df.columns for c in uk):
    dup_uk = int(df.duplicated(subset=uk).sum())
    ukstr = ','.join(uk)
else:
    dup_uk, ukstr = -1, '(uk 列不全，跳过)'
total = len(df)
dts = sorted(df['dt'].unique()) if 'dt' in df.columns else []
lo, hi = (dts[0], dts[-1]) if dts else ('-', '-')
print(total, lo, hi, dup_full, dup_uk, ukstr)
PY
) || { echo "❌ 中止：CSV 预检失败" >&2; exit 1; }
read -r NROWS DMIN DMAX DUPFULL DUPUK UKCOLS <<<"$meta"
[ -n "$NROWS" ] && [ -n "$DMIN" ] && [ -n "$DMAX" ] || { echo "❌ 中止：元信息解析失败（输出: '$meta'）" >&2; exit 1; }
echo "数据行 $NROWS，dt 范围 $DMIN ~ $DMAX；整行重复 $DUPFULL，uk($UKCOLS) 重复 $DUPUK"
if [ "$MODE" = "clear" ] && { [ "$DMIN" = "-" ] || [ "$DMIN" = "None" ]; }; then
  echo "❌ 中止：--mode clear 需要 CSV 含有效 dt 列以确定删除范围（否则无法幂等）" >&2; exit 2
fi
if [ "${DUPFULL:-0}" -gt 0 ] || [ "${DUPUK:-0}" -gt 0 ]; then
  echo "❌ 中止：检测到重复（整行 $DUPFULL / uk $DUPUK），请先在数据/上游修正后重导" >&2; exit 2
fi

# ── 门3：clear 模式先删 ───────────────────────────────────────
if [ "$MODE" = "clear" ]; then
  pre=$(lark-cli apps +db-execute --app-id $APP --environment "$ENV" --yes --sql "SELECT count(*) n FROM $TABLE WHERE dt BETWEEN '$DMIN' AND '$DMAX'" 2>&1 | grep -oE '"n": [0-9]+' | grep -oE '[0-9]+' || echo '?')
  echo "clear：删除既有 $pre 行（dt $DMIN~$DMAX）"
  # || true 必须保留：set -e 下 DELETE 非零退出（如大表超时）会在本行静默杀死脚本，
  # 下行错误处理器永远执行不到、日志断在 clear 行（2026-10-30 online 257k 行实测）；
  # 与校验段（下文 vt 重试处）同一陷阱同一修法。失败判定交给循环后的 grep。
  # 网络抖动重试 1 次（2026-10-31）：DELETE 按 dt 范围幂等——首次实际生效但响应超时的场景，
  # 重执行只是删 0 行，安全；两次都失败才中止（未做任何导入）。
  del=""
  for dtry in 1 2; do
    del=$(lark-cli apps +db-execute --app-id $APP --environment "$ENV" --yes --sql "DELETE FROM $TABLE WHERE dt BETWEEN '$DMIN' AND '$DMAX'" 2>&1) || true
    echo "$del" | grep -q '"ok": true' && break
    [ "$dtry" = 1 ] && { echo "DELETE 未成功（疑网络抖动），3s 后重试..."; sleep 3; }
  done
  echo "$del" | grep -q '"ok": true' || { echo "❌ 中止：DELETE 重试后仍未成功，未做任何导入。原始输出:" >&2; echo "$del" >&2; exit 1; }
fi

# ── 分片（pyarrow 流式 + 字节预算 ≤900KB/片，原样保留文本精度；可选无损修复开关） ──
"$PY" -I - "$CSV" "$TMP" "$FIXINT" <<'PY'
import csv, io, os, re, sys
import pyarrow as pa
import pyarrow.csv as pac
path, tmp = sys.argv[1], sys.argv[2]
fixint = sys.argv[3] == '1'
LIMIT = 900_000
MAXROWS = 4800  # 平台单请求 ≤5000 行（k_dl_4000007），留余量
INTFLOAT = re.compile(r'^(-?\d+)\.0+$')
with open(path, newline='', encoding='utf-8-sig') as f:
    names = next(csv.reader(f))
reader = pac.open_csv(path,
                      read_options=pac.ReadOptions(autogenerate_column_names=False),
                      convert_options=pac.ConvertOptions(column_types=pa.schema([(c, pa.string()) for c in names])))
def rb(row):
    b = io.StringIO(); csv.writer(b, quoting=csv.QUOTE_MINIMAL).writerow(row); return len(b.getvalue().encode())
buf, header, n, size = None, None, 0, 0
fixed = written = 0
def flush():
    global buf, n, size
    if buf and len(buf) > 1:
        out = f'{tmp}/part_{n:03d}.csv'
        with open(out, 'w', newline='', encoding='utf-8') as g:
            csv.writer(g, quoting=csv.QUOTE_MINIMAL).writerows(buf)
        assert os.path.getsize(out) < 1_000_000, out
        n += 1
    buf = [header]; size = rb(header) if header else 0
for batch in reader:
    if header is None:
        header = batch.column_names
        size = rb(header); buf = [header]
    cols = [batch.column(i) for i in range(batch.num_columns)]  # 每批必须重建（列数组随批失效）
    for r in range(batch.num_rows):
        row = [c[r].as_py() for c in cols]
        if fixint:
            for i, v in enumerate(row):
                if v:
                    m = INTFLOAT.match(v)
                    if m:
                        row[i] = m.group(1); fixed += 1
        x = rb(row)
        if len(buf) - 1 >= MAXROWS or (size + x > LIMIT and len(buf) > 1):
            flush()
        buf.append(row); size += x; written += 1
flush()
open(f'{tmp}/written', 'w').write(f'{written} {fixed}')
extra = ('，整数化 ' + str(fixed) + ' 格') if fixint else ''
print(f'分片：{n} 个（≤900KB 且 ≤4800 行/片）写出 {written} 行{extra}')
PY
total=0
for f in "$TMP"/part_*.csv; do
  for try in 1 2; do
    if out=$(lark-cli apps +db-data-import --app-id $APP --table "$TABLE" --environment "$ENV" --file "$f" --yes 2>&1) && echo "$out" | grep -q '"ok": true'; then
      rows=$(echo "$out" | grep -oE '"rows": [0-9]+' | grep -oE '[0-9]+' || echo 0)
      total=$((total+rows)); echo "$(basename "$f") ok +$rows（累计 $total/$NROWS）"; break
    fi
    if [ "$try" = 2 ]; then echo "❌ FAILED $(basename "$f")：$(echo "$out" | grep -oE '"message": "[^"]*"' | head -1)" >&2; exit 1; fi
    echo "重试 $(basename "$f")"; sleep 2
  done
done

# ── 校验 ──────────────────────────────────────────────────────
if [ "$MODE" = "clear" ]; then
  EXP=$(awk '{print $1}' "$TMP/written")  # 期望=实际写出行数（开启 --dedup 时小于 CSV 原始行数）
  # 校验查询带重试：lark-cli 端点偶发 timeout（2026-10-26 online 50361 行案例：
  # 数据全部写成功，仅 COUNT 查询超时 → 误判 FAIL）。查询失败≠导入失败，重试 3 次再裁决。
  post='?'
  for vt in 1 2 3; do
    # || true 必须保留：set -e 下 grep 空匹配（超时场景）会直接杀死脚本，重试形同虚设
    p=$(lark-cli apps +db-execute --app-id $APP --environment "$ENV" --yes --sql "SELECT count(*) n FROM $TABLE WHERE dt BETWEEN '$DMIN' AND '$DMAX'" 2>&1 | grep -oE '"n": [0-9]+' | grep -oE '[0-9]+' || true)
    [ -n "$p" ] && { post="$p"; break; }
    [ "$vt" -lt 3 ] && { echo "校验查询未返回结果（第 $vt/3 次，疑端点抖动），3s 后重试..."; sleep 3; }
  done
  [ "$post" = "$EXP" ] && echo "✅ 校验通过：$post/$EXP（CSV 原始 $NROWS 行）" || { echo "❌ 校验不符：库内 $post ≠ 写出 $EXP" >&2; exit 1; }
else
  echo "append 完成：导入 $total 行（未做范围删除，行数校验跳过）"
fi
