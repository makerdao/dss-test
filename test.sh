#!/usr/bin/env bash
set -e

[[ $ETH_RPC_URL  ]] || { echo "Please set an ETH_RPC_URL"; exit 1; }

export FOUNDRY_ROOT_CHAINID="$(cast chain-id)"
if [ "$FOUNDRY_ROOT_CHAINID" != "1" ] && [ "$FOUNDRY_ROOT_CHAINID" != "5" ]; then
  echo "Invalid chainid of $FOUNDRY_ROOT_CHAINID. Please set your forking environment via ETH_RPC_URL."
  exit
fi
if [[ -z "$1" ]]; then
  forge test
else
  forge test --match "$1" -vvvvv
fi
