#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
: "${CUSTOMER_ID:?}"; : "${CUSTOMER_EMAIL:?}"
echo "Creating customer: $CUSTOMER_ID"
cb_post "/customers" \
  -d "id=$CUSTOMER_ID" \
  -d "email=$CUSTOMER_EMAIL" \
  -d "first_name=$CUSTOMER_FIRST_NAME" \
  -d "last_name=$CUSTOMER_LAST_NAME" \
  -d "auto_collection=off" \
  | save_json "03_create_customer.json"
