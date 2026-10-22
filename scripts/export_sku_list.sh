#!/bin/bash
# 临时脚本：导出 SKU×四级类目×商家 清单（含固定生效期），用于 biz_sku_target 预置数据
# 用法: ./export_sku_list.sh [dev|online]   默认 dev
set -euo pipefail
ENV="${1:-dev}"
OUT="./sku_mct_cat_${ENV}_$(date +%Y%m%d%H%M).csv"
SQL="select sku_id, category_level4_id, merchant_id, '2026-10-10' AS start_date, '2026-10-26' AS end_date FROM ads_sku_daily GROUP BY sku_id, category_level4_id, merchant_id"
lark-cli apps +db-execute --app-id app_17g5uw7qhs7 --environment "$ENV" --yes --sql "$SQL" > ./sku_export_raw.json
python3 -I - <<'PY'
import json, csv
raw = json.load(open('./sku_export_raw.json'))
assert raw.get('ok'), raw
rows = raw['data']
cols = ['sku_id', 'category_level4_id', 'merchant_id', 'start_date', 'end_date']
import os
out = os.environ.get('OUT_CSV', './sku_mct_cat.csv')
with open(out, 'w', newline='', encoding='utf-8') as f:
    w = csv.writer(f); w.writerow(cols)
    for r in rows:
        w.writerow([r.get(c) for c in cols])
print(f'{out}: {len(rows)} 行')
PY
mv ./sku_export_raw.json "${OUT%.csv}.json" 2>/dev/null || true
echo "输出: $OUT"
