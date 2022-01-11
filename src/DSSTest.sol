// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.12;

import "ds-test/test.sol";
import "dss-interfaces/Interfaces.sol";

// NOTE this contains some extra Foundry-only calls
// If using DappTools check if things are available
interface Vm {
    // Set block.timestamp (newTimestamp)
    function warp(uint256) external;
    // Set block.height (newHeight)
    function roll(uint256) external;
    // Loads a storage slot from an address (who, slot)
    function load(address,bytes32) external returns (bytes32);
    // Stores a value to an address' storage slot, (who, slot, value)
    function store(address,bytes32,bytes32) external;
    // Signs data, (privateKey, digest) => (r, v, s)
    function sign(uint256,bytes32) external returns (uint8,bytes32,bytes32);
    // Gets address for a given private key, (privateKey) => (address)
    function addr(uint256) external returns (address);
    // Performs a foreign function call via terminal, (stringInputs) => (result)
    function ffi(string[] calldata) external returns (bytes memory);
    // Performs the next smart contract call with specified `msg.sender`, (newSender)
    function prank(address) external;
    // Performs all the following smart contract calls with specified `msg.sender`, (newSender)
    function startPrank(address) external;
    // Stop smart contract calls using the specified address with prankStart()
    function stopPrank() external;
    // Sets an address' balance, (who, newBalance)
    function deal(address, uint256) external;
    // Sets an address' code, (who, newCode)
    function etch(address, bytes calldata) external;
    // Expects an error on next call
    function expectRevert(bytes calldata) external;
    // Expects the next emitted event. Params check topic 1, topic 2, topic 3 and data are the same.
    function expectEmit(bool, bool, bool, bool) external;
    // Mocks a call to an address, returning specified data.
    // Calldata can either be strict or a partial match, e.g. if you only
    // pass a Solidity selector to the expected calldata, then the entire Solidity
    // function will be mocked.
    function mockCall(address,bytes calldata,bytes calldata) external;
    // Clears all mocked calls
    function clearMockedCalls() external;
    // Expect a call to an address with the specified calldata.
    // Calldata can either be strict or a partial match
    function expectCall(address,bytes calldata) external;
}

abstract contract DSSBaseTest is DSTest {

    Vm vm;

    uint256 constant WAD = 10 ** 18;
    uint256 constant RAY = 10 ** 27;
    uint256 constant RAD = 10 ** 45;
    uint256 constant BPS = 10 ** 4;

    function setUp() public virtual {
        vm = Vm(HEVM_ADDRESS);
    }

    function postSetup() internal virtual;

    /// @dev 
    function giveAuthAccess(address _base, address target) internal {
        WardsAbstract base = WardsAbstract(_base);

        // Edge case - ward is already set
        if (base.wards(target) == 1) return;

        for (int i = 0; i < 100; i++) {
            // Scan the storage for the ward storage slot
            bytes32 prevValue = vm.load(
                address(base),
                keccak256(abi.encode(target, uint256(i)))
            );
            vm.store(
                address(base),
                keccak256(abi.encode(target, uint256(i))),
                bytes32(uint256(1))
            );
            if (base.wards(target) == 1) {
                // Found it
                return;
            } else {
                // Keep going after restoring the original value
                vm.store(
                    address(base),
                    keccak256(abi.encode(target, uint256(i))),
                    prevValue
                );
            }
        }

        // We have failed if we reach here
        assertTrue(false);
    }

    function giveTokens(address token, uint256 amount) internal {
        // Edge case - balance is already set for some reason
        if (DSTokenAbstract(token).balanceOf(address(this)) == amount) return;

        for (uint256 i = 0; i < 200; i++) {
            // Scan the storage for the balance storage slot
            bytes32 prevValue = vm.load(
                token,
                keccak256(abi.encode(address(this), uint256(i)))
            );
            vm.store(
                token,
                keccak256(abi.encode(address(this), uint256(i))),
                bytes32(amount)
            );
            if (DSTokenAbstract(token).balanceOf(address(this)) == amount) {
                // Found it
                return;
            } else {
                // Keep going after restoring the original value
                vm.store(
                    token,
                    keccak256(abi.encode(address(this), uint256(i))),
                    prevValue
                );
            }
        }

        // We have failed if we reach here
        assertTrue(false);
    }

}

abstract contract DSSUnitTest is DSSBaseTest {

    // TODO: deploy a full mock MCD

}

abstract contract DSSGoerliIntegrationTest is DSSBaseTest {

    // TODO: Same as mainnet, but with Goerli contracts

}

abstract contract DSSMainnetIntegrationTest is DSSBaseTest {

    VatAbstract public vat;
    DaiJoinAbstract public daiJoin;
    DaiAbstract public dai;
    VowAbstract public vow;
    IlkRegistryAbstract public ilkRegistry;
    // TODO add the rest

    function setUp() public virtual override {
        super.setUp();

        vat = VatAbstract(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
        daiJoin = DaiJoinAbstract(0x9759A6Ac90977b93B58547b4A71c78317f391A28);
        dai = DaiAbstract(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        vow = VowAbstract(0xA950524441892A31ebddF91d3cEEFa04Bf454466);
        ilkRegistry = IlkRegistryAbstract(0x5a464C28D19848f44199D003BeF5ecc87d090F87);
        
        postSetup();
    }

}
