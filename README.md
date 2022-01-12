# dss-test

Modern test framework for Maker repositories. Get up and running with MCD faster.

## Getting Started

First do `forge install makerdao/dss-test` (or dapp equivalent) in your newly setup repository.

Sample test:

```
pragma solidity 0.8.9;

import "dss-test/DSSTest.sol";

contract IntegrationTest is DSSTest {

    using GodMode for *;

    MCDUser myUser;

    function setupEnv() internal virtual override returns (MCD) {
        return autoDetectEnv();
    }

    function postSetup() internal virtual override {
        myUser = mcd.newUser();
    }

    function test_give_tokens() public {
        mcd.dai().setBalance(address(this), 100 ether);
        assertEq(mcd.dai().balanceOf(address(this)), 100 ether);
    }

    function test_create_liquidation() public {
        uint256 prevKicks = mcd.wethAClip().kicks();
        myUser.createAuction(mcd.wethAJoin(), 100 ether);
        assertEq(mcd.wethAClip().kicks(), prevKicks + 1);
    }

}
```

`setupEnv()` and `postSetup()` are hooks which allow you to configure both the environment you are in (mainnet, goerli, mocked) as well as an setup stuff that would normally go in `setUp()`. There is a special `GodMode` library which provides useful functions such as giving `auth` access to an arbitrary contract or setting token balances to any amount. You can also use `GodMode.vm()` to access all the underlying vm cheat codes.

### MCD

An `MCD` instance is mostly just for keeping a bundle of references to all the common mcd contracts. If you are doing integration testing this can be set by either instantiating `MCDMainnet` or `MCDGoerli` or just use `autoDetectEnv()` to do this automatically. `MCD` also provides some high level functions:

 * `deployIlk(address join)` - This will deploy a new ilk to the vat along with standard liquidation and oracle components.


### MCDUser

`MCDUser` instances can be used to interact with `MCD`. They represent the end users and can perform any number of actions. Usually what you will want to do is inherit this contract and extend the functionality to whatever library you are building. `MCDUser` provides some high level functions:

 * `createAuction(address join, uint256 amount)` - Kicks off a new auction for the specified `join` adapter for the `amount` of collateral specified.
