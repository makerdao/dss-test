#!/usr/bin/env bash
set -e

[[ -n "$FOUNDRY_ROOT_CHAINID" ]] || {
    [[ -n $ETH_RPC_URL ]] || {
        echo "Please set FOUNDRY_ROOT_CHAINID (1 or 5) or ETH_RPC_URL";
        exit 1;
    }
    FOUNDRY_ROOT_CHAINID="$(cast chain-id)"
}
[[ "$FOUNDRY_ROOT_CHAINID" == "1" ]] || [[ "$FOUNDRY_ROOT_CHAINID" == "5" ]] || {
    echo "Invalid chainid of $FOUNDRY_ROOT_CHAINID. Please set your forking environment via ETH_RPC_URL or manually by defining FOUNDRY_ROOT_CHAINID (1 or 5)."
    exit 1;
}

[[ "$FOUNDRY_ROOT_CHAINID" == "1" ]] && echo "Running tests on Mainnet"
[[ "$FOUNDRY_ROOT_CHAINID" == "5" ]] && echo "Running tests on Goerli"

mkdir -p "script/output/$FOUNDRY_ROOT_CHAINID"

export FOUNDRY_ROOT_CHAINID
if [[ -z "$1" ]]; then
    forge test
else
    forge test --match-test "$1" -vvvvv
fi
