#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -f "$ROOT_DIR/.env" ]; then
  set -a
  source "$ROOT_DIR/.env"
  set +a
else
  echo "Missing .env. Copy .env.example to .env and edit it." >&2
  exit 1
fi
: "${CHARGEBEE_SITE:?Set CHARGEBEE_SITE}"
: "${CHARGEBEE_API_KEY:?Set CHARGEBEE_API_KEY}"
BASE_URL="https://${CHARGEBEE_SITE}.chargebee.com/api/v2"
DATA_DIR="$ROOT_DIR/data"
mkdir -p "$DATA_DIR"
cb_get() {
  local path="$1"; shift || true
  curl -sS -u "${CHARGEBEE_API_KEY}:" "$BASE_URL$path" "$@"
}
cb_post() {
  local path="$1"; shift || true
  curl -sS -u "${CHARGEBEE_API_KEY}:" -X POST "$BASE_URL$path" "$@"
}
save_json() {
  local filename="$1"
  tee "$DATA_DIR/$filename" | python3 -m json.tool > "$DATA_DIR/${filename%.json}.pretty.json" || true
  echo "\nSaved: data/$filename and data/${filename%.json}.pretty.json" >&2
}
