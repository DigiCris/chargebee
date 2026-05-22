#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
: "${ITEM_ID:?}"; : "${ITEM_PRICE_ID:?}"; : "${PRICE_CENTS:?}"; : "${CURRENCY:?}"; : "${PERIOD:?}"; : "${PERIOD_UNIT:?}"
echo "Creating item price: $ITEM_PRICE_ID"
cb_post "/item_prices" \
  -d "id=$ITEM_PRICE_ID" \
  -d "name=$ITEM_PRICE_NAME" \
  -d "item_id=$ITEM_ID" \
  -d "pricing_model=flat_fee" \
  -d "price=$PRICE_CENTS" \
  -d "currency_code=$CURRENCY" \
  -d "period=$PERIOD" \
  -d "period_unit=$PERIOD_UNIT" \
  | save_json "02_create_item_price.json"
