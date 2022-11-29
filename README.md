# dss-test

Modern test framework for Maker repositories to get up and running with MCD faster. Extends `forge-std`.

## Getting Started

First do `forge install makerdao/dss-test` (or dapp equivalent) in your newly setup repository.

Look at `src/tests/IntegrationTest.t.sol` for a bunch of examples.

There is a special `GodMode` library which provides useful functions such as giving `auth` access to an arbitrary contract or setting token balances to any amount.

### MCD

An `DssInstance` is mostly just for keeping a bundle of references to all the common mcd contracts. If you are doing integration testing this can be loaded from the chainlog automatically with `MCD.loadFromChainlog()`. `MCD` also provides some high level functions:

 * `initIlk(...)` - This will deploy a new ilk to the `DssInstance` along with standard liquidation and oracle components.


### MCDUser

`MCDUser` instances can be used to interact with `MCD`. They represent the end users and can perform any number of actions. Usually what you will want to do is inherit this contract and extend the functionality to whatever library you are building. `MCDUser` provides some high level functions:

 * `createAuction(address join, uint256 amount)` - Kicks off a new auction for the specified `join` adapter for the `amount` of collateral specified.
