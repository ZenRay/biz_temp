!#/bin/bash
set -euo pipefail
ENV="${1:-dev}"
OUT="/tmp/sku_mct_cat_${ENV}_$(date +%Y%m%d%H%M).csv"
SQL="select sku_id, category_level4_id, merchant_id, '2026-10-10' AS start_date, '2026-10-26' AS end_date FROM ads_sku_daily GROUP BY sku_id, category_level4_id, merchant_id"
lark-cli apps +db-execute --app-id app_17g5uw7qhs7 --environment "$ENV" --yes --sql "$SQL" > ./result.json
