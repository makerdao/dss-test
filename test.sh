#!/usr/bin/env bash
set -e

export FOUNDRY_ROOT_CHAINID="$(cast chain-id)"

if [[ -z "$1" ]]; then
  forge test
else
  forge test --match "$1" -vvvvv
fi
