#!/usr/bin/env bash
set -e

for ARGUMENT in "$@"
do
    KEY=$(echo "$ARGUMENT" | cut -f1 -d=)
    VALUE=$(echo "$ARGUMENT" | cut -f2 -d=)

    case "$KEY" in
            match)      MATCH="$VALUE" ;;
            block)      BLOCK="$VALUE" ;;
            opt-block)   OPT_BLOCK="$VALUE" ;;
            arb-block)   ARB_BLOCK="$VALUE" ;;
            *)
    esac
done

# L2 setup

if [[ -z "$OPT_RPC_URL" ]]; then
    echo "OPTIMISM not used"
    export OPT_RPC_URL=""
fi

if [[ -z "$ARB_RPC_URL" ]]; then
    echo "ARBITRUM not used"
    export ARB_RPC_URL=""
fi

if [[ -z "$OPT_BLOCK" ]]; then
    export OPT_BLOCK=0
else
    export OPT_BLOCK=$OPT_BLOCK
fi

if [[ -z "$OPT_BLOCK" ]]; then
    export ARB_BLOCK=0
else
    export ARB_BLOCK=$ARB_BLOCK
fi

if [[ -z "$MATCH" && -z "$BLOCK" ]]; then
  forge test --fork-url "$ETH_RPC_URL"
elif [[ -z "$BLOCK" ]]; then
  forge test --fork-url "$ETH_RPC_URL" --match "$MATCH" -vvv --force
elif [[ -z "$MATCH" ]]; then
  forge test --fork-url "$ETH_RPC_URL" --fork-block-number "$BLOCK" -vvv --force
else
  forge test --fork-url "$ETH_RPC_URL" --match "$MATCH" --fork-block-number "$BLOCK" -vvv --force
fi
