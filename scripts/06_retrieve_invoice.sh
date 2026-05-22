#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
: "${INVOICE_ID:?Set INVOICE_ID in .env}"
echo "Retrieving invoice: $INVOICE_ID"
cb_get "/invoices/$INVOICE_ID" | save_json "06_retrieve_invoice.json"
