#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
: "${ITEM_ID:?}"; : "${ITEM_NAME:?}"; : "${ITEM_FAMILY_ID:?}"
echo "Creating plan item: $ITEM_ID"
cb_post "/items" \
  -d "id=$ITEM_ID" \
  -d "name=$ITEM_NAME" \
  -d "type=plan" \
  -d "item_family_id=$ITEM_FAMILY_ID" \
  -d "metadata[merchant_id]=$MERCHANT_ID" \
  | save_json "01_create_item.json"
