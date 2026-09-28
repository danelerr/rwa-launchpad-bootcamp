#!/usr/bin/env bash
# Original bootcamp admin tool, split into actions so setup does not withdraw
# funds before the investor has paid. Default: initialize + whitelist.
set -euo pipefail

NETWORK="${NETWORK:-testnet}"
ADMIN_KEY="${ADMIN_KEY:-alice}"
: "${CONTRACT_ID:?Set CONTRACT_ID}"
ADMIN="$(stellar keys address "$ADMIN_KEY")"

invoke() {
  stellar contract invoke --id "$CONTRACT_ID" --source "$ADMIN_KEY" \
    --network "$NETWORK" -- "$@"
}

initialize() {
  : "${PAYMENT_TOKEN:?Set PAYMENT_TOKEN}"
  echo "=== ADMIN: initialize ==="
  invoke initialize --admin "$ADMIN" \
    --asset '{"name":"RWAToken","total_supply":"1000000","price_per_unit":"100","payment_token":"'"$PAYMENT_TOKEN"'","paused":false}'
}

whitelist() {
  : "${INVESTOR:?Set INVESTOR to the investor public address}"
  echo "=== ADMIN: whitelist investor $INVESTOR ==="
  invoke set_whitelist --admin "$ADMIN" --investor "$INVESTOR" --approved true
}

case "${1:-setup}" in
  setup) initialize; whitelist ;;
  initialize) initialize ;;
  whitelist) whitelist ;;
  mint)
    : "${INVESTOR:?Set INVESTOR}"
    invoke mint --admin "$ADMIN" --to "$INVESTOR" --amount "${AMOUNT:-100}"
    ;;
  withdraw)
    : "${TREASURY:?Set TREASURY}"
    invoke withdraw --admin "$ADMIN" --to "$TREASURY" --amount "${AMOUNT:-500}"
    ;;
  pause|unpause) invoke "$1" --admin "$ADMIN" ;;
  *) echo "Usage: $0 [setup|initialize|whitelist|mint|withdraw|pause|unpause]" >&2; exit 2 ;;
esac
