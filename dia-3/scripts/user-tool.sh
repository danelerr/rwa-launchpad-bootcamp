#!/usr/bin/env bash
# Original bootcamp user tool, adapted to the Week 4 minimum-investment demo.
# Amounts use the integer units of invest(payment_amount), not display decimals.
set -euo pipefail

NETWORK="${NETWORK:-testnet}"
USER_KEY="${USER_KEY:-bob}"
: "${CONTRACT_ID:?Set CONTRACT_ID}"
INVESTOR="$(stellar keys address "$USER_KEY")"

invoke() {
  stellar contract invoke --id "$CONTRACT_ID" --source "$USER_KEY" \
    --network "$NETWORK" -- "$@"
}

balance() {
  stellar contract invoke --id "$CONTRACT_ID" --source "$USER_KEY" \
    --network "$NETWORK" --send=no -- balance --id "$INVESTOR"
}

number() {
  # Stellar CLI serializes i128 values as JSON strings.
  tr -d '\r\n" '
}

demo() {
  echo "=== Stellar Elite Bolivia / Semana 4 ==="
  echo "Network: $NETWORK"
  echo "Contract: $CONTRACT_ID"
  echo "Investor: $INVESTOR"
  local before after_failure after_success failure status minted
  before="$(balance | number)"
  echo "RWA balance before: $before"

  echo "=== INVEST 100: expected AmountTooLow (Contract #7) ==="
  if failure="$(invoke invest --investor "$INVESTOR" --payment_amount 100 2>&1)"; then
    printf '%s\n' "$failure"
    echo "FAIL: investment of 100 unexpectedly succeeded" >&2
    return 1
  else
    status=$?
  fi
  printf '%s\n' "$failure"
  if [[ "$failure" != *"Error(Contract, #7)"* ]]; then
    echo "FAIL: rejected for an unexpected reason" >&2
    return 1
  fi
  echo "PASS: 100 rejected by AmountTooLow; CLI exit status $status"
  echo "The CLI rejects this during simulation; no failed transaction is submitted."
  after_failure="$(balance | number)"
  [[ "$after_failure" == "$before" ]] || { echo "FAIL: balance changed" >&2; return 1; }
  echo "RWA balance after rejection: $after_failure (unchanged)"

  echo "=== INVEST 500: expected success ==="
  minted="$(invoke invest --investor "$INVESTOR" --payment_amount 500 | number)"
  echo "RWA minted: $minted"
  [[ "$minted" == 5 ]] || { echo "FAIL: expected 5 RWA at price 100" >&2; return 1; }

  echo "=== BALANCE ==="
  after_success="$(balance | number)"
  [[ "$after_success" == "$((before + 5))" ]] || { echo "FAIL: incorrect RWA balance" >&2; return 1; }
  echo "RWA balance after successful investment: $after_success"
  echo "PASS: 100 rejected / 500 accepted / balance increased by 5 RWA"
}

case "${1:-demo}" in
  demo) demo ;;
  invest) invoke invest --investor "$INVESTOR" --payment_amount "${AMOUNT:-500}" ;;
  balance) balance ;;
  transfer)
    : "${RECIPIENT:?Set RECIPIENT}"
    invoke transfer --from "$INVESTOR" --to "$RECIPIENT" --amount "${AMOUNT:-1}"
    ;;
  *) echo "Usage: $0 [demo|invest|balance|transfer]" >&2; exit 2 ;;
esac
