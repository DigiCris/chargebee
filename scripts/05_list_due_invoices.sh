#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
echo "Listing payment_due invoices."
cb_get "/invoices" -G \
  --data-urlencode "limit=10" \
  --data-urlencode "status[is]=payment_due" \
  | save_json "05_list_due_invoices.json"
echo "Copy the invoice.id you want into INVOICE_ID in .env."
