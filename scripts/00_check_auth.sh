#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
echo "Checking Chargebee auth against site: $CHARGEBEE_SITE"
cb_get "/customers" -G --data-urlencode "limit=1" | save_json "00_auth_check.json"
echo "OK if the response contains list/customers and no api_error_code."
