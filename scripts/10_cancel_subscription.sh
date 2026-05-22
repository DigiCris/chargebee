#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
: "${SUBSCRIPTION_ID:?Set SUBSCRIPTION_ID in .env}"
echo "Cancelling subscription immediately: $SUBSCRIPTION_ID"
cb_post "/subscriptions/$SUBSCRIPTION_ID/cancel_for_items" -d "end_of_term=false" | save_json "10_cancel_subscription.json"
