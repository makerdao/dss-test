#!/usr/bin/env bash
set -e

if [[ -z "$1" ]]; then
  forge test --rpc-url="$ETH_RPC_URL" --force
else
  forge test --rpc-url="$ETH_RPC_URL" --match "$1" -vvv --force
fi
