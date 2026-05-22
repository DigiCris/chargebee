#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
: "${SUBSCRIPTION_ID:?Set SUBSCRIPTION_ID in .env}"
echo "Retrieving subscription: $SUBSCRIPTION_ID"
cb_get "/subscriptions/$SUBSCRIPTION_ID" | save_json "08_retrieve_subscription.json"
