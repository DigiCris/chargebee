#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
: "${INVOICE_ID:?Set INVOICE_ID in .env}"; : "${RECORD_PAYMENT_AMOUNT_CENTS:?}"
echo "Recording offline payment for invoice $INVOICE_ID amount $RECORD_PAYMENT_AMOUNT_CENTS cents"
cb_post "/invoices/$INVOICE_ID/record_payment" \
  -d "transaction[amount]=$RECORD_PAYMENT_AMOUNT_CENTS" \
  -d "transaction[payment_method]=bank_transfer" \
  -d "transaction[status]=success" \
  -d "comment=POC: mock crypto payment executed by Luca" \
  | save_json "07_record_payment.json"
