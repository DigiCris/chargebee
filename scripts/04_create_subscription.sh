#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

: "${CUSTOMER_ID:?}"
: "${ITEM_PRICE_ID:?}"

echo "Creating subscription for customer $CUSTOMER_ID using $ITEM_PRICE_ID"

cb_post "/customers/$CUSTOMER_ID/subscription_for_items" \
  -d "subscription_items[item_price_id][0]=$ITEM_PRICE_ID" \
  -d "subscription_items[quantity][0]=1" \
  -d "auto_collection=off" \
  | save_json "04_create_subscription.json"

echo "Open data/04_create_subscription.pretty.json and copy subscription.id and invoice.id if returned."
