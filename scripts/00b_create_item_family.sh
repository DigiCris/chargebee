#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
: "${ITEM_FAMILY_ID:?Set ITEM_FAMILY_ID}"
: "${ITEM_FAMILY_NAME:?Set ITEM_FAMILY_NAME}"
echo "Creating item family: $ITEM_FAMILY_ID"
cb_post "/item_families" -d "id=$ITEM_FAMILY_ID" -d "name=$ITEM_FAMILY_NAME" | save_json "00b_create_item_family.json"
