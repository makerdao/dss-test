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

    // Commonly used addresses

    // Core MCD
    VatAbstract public vat;
    DaiJoinAbstract public daiJoin;
    DaiAbstract public dai;
    VowAbstract public vow;
    DogAbstract public dog;
    PotAbstract public pot;
    JugAbstract public jug;
    SpotAbstract public spotter;

    // ETH-A
    DSTokenAbstract public weth;
    OsmAbstract public wethPip;
    GemJoinAbstract public wethAJoin;
    ClipAbstract public wethAClip;

    // WBTC-A
    DSTokenAbstract public wbtc;
    OsmAbstract public wbtcPip;
    GemJoinAbstract public wbtcAJoin;
    ClipAbstract public wbtcAClip;

    function setUp() public virtual {
        vm = Vm(HEVM_ADDRESS);
    }

    function postSetup() internal virtual;

    /// @dev Gives `target` contract admin access on the `base`
    function giveAuthAccess(address base, address target) internal {
        // Edge case - ward is already set
        if (WardsAbstract(base).wards(target) == 1) return;

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
            if (WardsAbstract(base).wards(target) == 1) {
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

    /// @dev Gives `who` `amount` number of tokens at address `token`.
    function giveTokens(address token, address who, uint256 amount) internal {
        // Edge case - balance is already set for some reason
        if (DSTokenAbstract(token).balanceOf(who) == amount) return;

        for (uint256 i = 0; i < 200; i++) {
            // Scan the storage for the balance storage slot
            bytes32 prevValue = vm.load(
                token,
                keccak256(abi.encode(who, uint256(i)))
            );
            vm.store(
                token,
                keccak256(abi.encode(who, uint256(i))),
                bytes32(amount)
            );
            if (DSTokenAbstract(token).balanceOf(who) == amount) {
                // Found it
                return;
            } else {
                // Keep going after restoring the original value
                vm.store(
                    token,
                    keccak256(abi.encode(who, uint256(i))),
                    prevValue
                );
            }
        }

        // We have failed if we reach here
        assertTrue(false);
    }

}

abstract contract DSSMockIntegrationTest is DSSBaseTest {

    // TODO: deploy a a base mock of MCD

}

abstract contract DSSGoerliIntegrationTest is DSSBaseTest {

    function setUp() public virtual override {
        super.setUp();

        vat = VatAbstract(0xB966002DDAa2Baf48369f5015329750019736031);
        daiJoin = DaiJoinAbstract(0x6a60b7070befb2bfc964F646efDF70388320f4E0);
        dai = DaiAbstract(0x11fE4B6AE13d2a6055C8D9cF65c55bac32B5d844);
        vow = VowAbstract(0x23f78612769b9013b3145E43896Fa1578cAa2c2a);
        dog = DogAbstract(0x5cf85A37Dbd28A239698B4F9aA9a03D55C04F292);
        pot = PotAbstract(0x50672F0a14B40051B65958818a7AcA3D54Bd81Af);
        jug = JugAbstract(0xC90C99FE9B5d5207A03b9F28A6E8A19C0e558916);
        spotter = SpotAbstract(0xACe2A9106ec175bd56ec05C9E38FE1FDa8a1d758);
        weth = DSTokenAbstract(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6);
        wethPip = OsmAbstract(0x94588e35fF4d2E99ffb8D5095F35d1E37d6dDf12);
        wethAJoin = GemJoinAbstract(0x2372031bB0fC735722AA4009AeBf66E8BEAF4BA1);
        wethAClip = ClipAbstract(0x2603c6EC5878dC70f53aD3a90e4330ba536d2385);
        wbtc = DSTokenAbstract(0x7ccF0411c7932B99FC3704d68575250F032e3bB7);
        wbtcPip = OsmAbstract(0xE7de200a3a29E9049E378b52BD36701A0Ce68C3b);
        wbtcAJoin = GemJoinAbstract(0x3cbE712a12e651eEAF430472c0C1BF1a2a18939D);
        wbtcAClip = ClipAbstract(0x752c35fa3d21863257bbBCB7e2B344fd0948B61b);
        
        postSetup();
    }

}

abstract contract DSSMainnetIntegrationTest is DSSBaseTest {

    function setUp() public virtual override {
        super.setUp();

        vat = VatAbstract(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
        daiJoin = DaiJoinAbstract(0x9759A6Ac90977b93B58547b4A71c78317f391A28);
        dai = DaiAbstract(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        vow = VowAbstract(0xA950524441892A31ebddF91d3cEEFa04Bf454466);
        dog = DogAbstract(0x135954d155898D42C90D2a57824C690e0c7BEf1B);
        pot = PotAbstract(0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7);
        jug = JugAbstract(0x19c0976f590D67707E62397C87829d896Dc0f1F1);
        spotter = SpotAbstract(0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3);
        weth = DSTokenAbstract(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        wethPip = OsmAbstract(0x81FE72B5A8d1A857d176C3E7d5Bd2679A9B85763);
        wethAJoin = GemJoinAbstract(0x2F0b23f53734252Bda2277357e97e1517d6B042A);
        wethAClip = ClipAbstract(0xc67963a226eddd77B91aD8c421630A1b0AdFF270);
        wbtc = DSTokenAbstract(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
        wbtcPip = OsmAbstract(0xf185d0682d50819263941e5f4EacC763CC5C6C42);
        wbtcAJoin = GemJoinAbstract(0xBF72Da2Bd84c5170618Fbe5914B0ECA9638d5eb5);
        wbtcAClip = ClipAbstract(0x0227b54AdbFAEec5f1eD1dFa11f54dcff9076e2C);
        
        postSetup();
    }

}
