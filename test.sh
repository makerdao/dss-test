#!/usr/bin/env bash
set -e

[[ $ETH_RPC_URL  ]] || { echo "Please set an ETH_RPC_URL"; exit 1; }
if [ -z "$FOUNDRY_ROOT_CHAINID" ]; then
  export FOUNDRY_ROOT_CHAINID="$(cast chain-id)"
fi
if [ "$FOUNDRY_ROOT_CHAINID" != "1" ] && [ "$FOUNDRY_ROOT_CHAINID" != "5" ]; then
  echo "Invalid chainid of $FOUNDRY_ROOT_CHAINID. Please set your forking environment via ETH_RPC_URL or manually by defining FOUNDRY_ROOT_CHAINID."
  exit
fi

if [[ -z "$1" ]]; then
  forge test
else
  forge test --match "$1" -vvvvv
fi
