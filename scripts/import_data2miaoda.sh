#!/bin/bash
# 通用 CSV → 应用库表导入（lark-cli），全部行为由参数控制：
#   --csv <路径>      数据文件（必需）
#   --table <表名>    目标表（必需）
#   --env <dev|online> 环境（必需；online 需另设 ONLINE_CONFIRM=1）
#   --mode <clear|append> clear=按 CSV 的 dt 范围先删后插（清空导入，幂等可重跑）
#                        append=直接追加（覆盖导入：撞唯一键由 DB 报错中止）
# 硬门（不可协商）：
#   1) 列核对先行：CSV 表头出现任何表外列（疑似拼写错误/多余列）→ 立即中止并输出差异，
#      由人修正数据文件或确认表结构后重试；脚本绝不自动改名/剔列。
#   2) 表内 NOT NULL 且无默认值的列在 CSV 中缺失 → 中止。
#   3) 任一分片失败重试一次后仍失败 → 中止（clear 模式可安全重跑）。
# 大数据量：按实测字节自动切 ≤900KB 分片（lark-cli 单请求 1MB 上限），逐片导入。
set -euo pipefail
APP=app_17g5uw7qhs7
CSV="" TABLE="" ENV="" MODE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --csv) CSV="${2:?}"; shift 2;;
    --table) TABLE="${2:?}"; shift 2;;
    --env) ENV="${2:?}"; shift 2;;
    --mode) MODE="${2:?}"; shift 2;;
    *) echo "未知参数: $1" >&2; exit 2;;
  esac
done
[ -n "$CSV" ] && [ -n "$TABLE" ] && [ -n "$ENV" ] && [ -n "$MODE" ] || { echo "用法: $0 --csv f.csv --table 表名 --env dev|online --mode clear|append" >&2; exit 2; }
case "$MODE" in clear|append) ;; *) echo "--mode 仅支持 clear|append" >&2; exit 2;; esac
case "$ENV" in dev|online) ;; *) echo "--env 仅支持 dev|online" >&2; exit 2;; esac
[ -f "$CSV" ] || { echo "文件不存在: $CSV" >&2; exit 2; }
if [ "$ENV" = "online" ] && [ "${ONLINE_CONFIRM:-0}" != "1" ]; then
  echo "!! online 生产库操作：确认请设 ONLINE_CONFIRM=1 重跑" >&2; exit 2
fi
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

# ── 门1：列核对（只读，零副作用） ─────────────────────────────
lark-cli apps +db-table-get --app-id $APP --table "$TABLE" --environment "$ENV" > "$TMP/tbl.json"
python3 -I - "$CSV" "$TMP/tbl.json" <<'PY'
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

# ── 元信息（行数/dt 范围） ────────────────────────────────────
read -r NROWS DMIN DMAX <<<"$(python3 -I - "$CSV" <<'PY'
import csv, sys
with open(sys.argv[1], newline='', encoding='utf-8-sig') as f:
    r = list(csv.reader(f))
h, rows = r[0], r[1:]
di = h.index('dt') if 'dt' in h else -1
dts = sorted({row[di] for row in rows}) if di >= 0 else []
print(len(rows), dts[0] if dts else '-', dts[-1] if dts else '-')
PY
)"
echo "数据行 $NROWS，dt 范围 $DMIN ~ $DMAX"
if [ "$MODE" = "clear" ] && [ "$DMIN" = "-" ]; then
  echo "❌ 中止：--mode clear 需要 CSV 含 dt 列以确定删除范围（否则无法幂等）" >&2; exit 2
fi

# ── 门2：clear 模式先删 ───────────────────────────────────────
if [ "$MODE" = "clear" ]; then
  pre=$(lark-cli apps +db-execute --app-id $APP --environment "$ENV" --yes --sql "SELECT count(*) n FROM $TABLE WHERE dt BETWEEN '$DMIN' AND '$DMAX'" 2>&1 | grep -oE '"n": [0-9]+' | grep -oE '[0-9]+' || echo '?')
  echo "clear：删除既有 $pre 行（dt $DMIN~$DMAX）"
  lark-cli apps +db-execute --app-id $APP --environment "$ENV" --yes --sql "DELETE FROM $TABLE WHERE dt BETWEEN '$DMIN' AND '$DMAX'" >/dev/null
fi

# ── 分片 + 逐片导入（失败重试一次） ────────────────────────────
python3 -I - "$CSV" "$TMP" <<'PY'
import csv, io, os, sys
path, tmp = sys.argv[1], sys.argv[2]
LIMIT = 900_000
with open(path, newline='', encoding='utf-8-sig') as f:
    r = list(csv.reader(f))
header, rows = r[0], r[1:]
def rb(row):
    b = io.StringIO(); csv.writer(b, quoting=csv.QUOTE_MINIMAL).writerow(row); return len(b.getvalue().encode())
hb = rb(header); n = ri = 0
while ri < len(rows):
    buf = [header]; size = hb
    while ri < len(rows):
        x = rb(rows[ri])
        if size + x > LIMIT and len(buf) > 1: break
        buf.append(rows[ri]); size += x; ri += 1
    out = f'{tmp}/part_{n:03d}.csv'
    with open(out, 'w', newline='', encoding='utf-8') as g:
        csv.writer(g, quoting=csv.QUOTE_MINIMAL).writerows(buf)
    assert os.path.getsize(out) < 1_000_000, out
    n += 1
print(f'分片：{n} 个（≤900KB/片）')
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
  post=$(lark-cli apps +db-execute --app-id $APP --environment "$ENV" --yes --sql "SELECT count(*) n FROM $TABLE WHERE dt BETWEEN '$DMIN' AND '$DMAX'" 2>&1 | grep -oE '"n": [0-9]+' | grep -oE '[0-9]+' || echo '?')
  [ "$post" = "$NROWS" ] && echo "✅ 校验通过：$post/$NROWS" || { echo "❌ 校验不符：库内 $post ≠ CSV $NROWS" >&2; exit 1; }
else
  echo "append 完成：导入 $total 行（未做范围删除，行数校验跳过）"
fi
