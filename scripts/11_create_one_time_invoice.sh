#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
: "${CUSTOMER_ID:?}"
: "${ITEM_PRICE_ID:?}"
echo "Creating one-time invoice for customer $CUSTOMER_ID using $ITEM_PRICE_ID"
cb_post "/invoices/create_for_charge_items_and_charges" -d "customer_id=$CUSTOMER_ID" -d "item_prices[item_price_id][0]=$ITEM_PRICE_ID" -d "item_prices[quantity][0]=1" | save_json "11_create_one_time_invoice.json"
echo "Copy invoice.id into INVOICE_ID in .env"
