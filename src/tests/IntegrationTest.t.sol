// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.8.16;

import "dss-interfaces/Interfaces.sol";

import "../DSSTest.sol";
import "../domains/MainnetDomain.sol";
import "../domains/OptimismDomain.sol";
import "../domains/ArbitrumDomain.sol";

interface OptimismDaiBridgeLike {
    function depositERC20To(address, address, address, uint256, uint32, bytes calldata) external;
    function withdrawTo(address, address, uint256, uint32, bytes calldata) external;
}

interface ArbitrumDaiBridgeLike {
    function l1Dai() external view returns (address);
    function outboundTransfer(address, address, uint256, uint256, uint256, bytes calldata) external payable;
    function outboundTransfer(address, address, uint256, bytes calldata) external;
}

contract IntegrationTest is DSSTest {

    using GodMode for *;

    MCDUser user1;
    MCDUser user2;
    MCDUser user3;

    OptimismDomain optimism;
    ArbitrumDomain arbitrum;

    function setupCrossChain() internal virtual override returns (Domain) {
        return new MainnetDomain();
    }

    function setupEnv() internal virtual override returns (MCD) {
        return autoDetectEnv();
    }

    function postSetup() internal virtual override {
        user1 = mcd.newUser();
        user2 = mcd.newUser();
        user3 = mcd.newUser();

        optimism = new OptimismDomain(primaryDomain);
        arbitrum = new ArbitrumDomain(primaryDomain);
    }

    function test_give_tokens() public {
        mcd.dai().setBalance(address(this), 100 ether);
        assertEq(mcd.dai().balanceOf(address(this)), 100 ether);
    }

    function test_create_liquidation() public {
        uint256 prevKicks = mcd.wethAClip().kicks();
        user1.createAuction(mcd.wethAJoin(), 100 ether);
        assertEq(mcd.wethAClip().kicks(), prevKicks + 1);
    }

    function test_auth() public {
        // Test that the vesting contract has proper auth setup
        // Note: can only test against newer style contracts that don't use LibNote
        checkAuth(mcd.chainlog().getAddress("MCD_VEST_DAI"), "DssVest");
    }

    function test_file_uint() public {
        // Test that the end contract has proper file
        // Note: can only test against newer style contracts that don't use LibNote
        checkFileUint(mcd.chainlog().getAddress("MCD_END"), "End", ["wait"]);
    }

    function test_file_address() public {
        // Test that the end contract has proper file
        // Note: can only test against newer style contracts that don't use LibNote
        checkFileAddress(mcd.chainlog().getAddress("MCD_END"), "End", ["vat", "cat", "dog", "vow", "pot", "spot"]);
    }

    function test_mcd_ilk() public {
        Ilk memory ilk = mcd.getIlk("ETH", "A");

        assertEq(address(ilk.gem), address(mcd.weth()));
        assertEq(address(ilk.pip), address(mcd.wethPip()));
        assertEq(address(ilk.join), address(mcd.wethAJoin()));
        assertEq(address(ilk.clip), address(mcd.wethAClip()));
    }

    function test_mcd_ilk_missing() public {
        Ilk memory ilk = mcd.getIlk("TKN", "A");

        assertEq(address(ilk.gem), address(0));
        assertEq(address(ilk.pip), address(0));
        assertEq(address(ilk.join), address(0));
        assertEq(address(ilk.clip), address(0));
    }

    function test_optimism_relay() public {
        DaiAbstract l2Dai = DaiAbstract(0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1);
        OptimismDaiBridgeLike l2Bridge = OptimismDaiBridgeLike(0x467194771dAe2967Aef3ECbEDD3Bf9a310C76C65);
        mcd.dai().setBalance(address(this), 100 ether);
        OptimismDaiBridgeLike bridge = OptimismDaiBridgeLike(mcd.chainlog().getAddress("OPTIMISM_DAI_BRIDGE"));

        // Transfer some DAI across the Optimism bridge
        mcd.dai().approve(address(bridge), 100 ether);
        bridge.depositERC20To(address(mcd.dai()), address(l2Dai), address(this), 100 ether, 1_000_000, "");

        // Message will be queued on L1, but not yet relayed
        assertEq(mcd.dai().balanceOf(address(this)), 0);

        // Relay the message
        optimism.relayL1ToL2();

        // We are on Optimism fork with message relayed now
        assertEq(l2Dai.balanceOf(address(this)), 100 ether);

        // Queue up an L2 -> L1 message
        l2Dai.approve(address(l2Bridge), 100 ether);
        l2Bridge.withdrawTo(address(l2Dai), address(this), 100 ether, 1_000_000, "");
        assertEq(l2Dai.balanceOf(address(this)), 0);

        // Relay the message
        optimism.relayL2ToL1();

        // We are on Mainnet fork with message relayed now
        assertEq(mcd.dai().balanceOf(address(this)), 100 ether);

        // Go back and forth one more time
        mcd.dai().approve(address(bridge), 50 ether);
        bridge.depositERC20To(address(mcd.dai()), address(l2Dai), address(this), 50 ether, 1_000_000, "");
        assertEq(mcd.dai().balanceOf(address(this)), 50 ether);

        optimism.relayL1ToL2();

        assertEq(l2Dai.balanceOf(address(this)), 50 ether);
        l2Dai.approve(address(l2Bridge), 25 ether);
        l2Bridge.withdrawTo(address(l2Dai), address(this), 25 ether, 1_000_000, "");
        assertEq(l2Dai.balanceOf(address(this)), 25 ether);

        optimism.relayL2ToL1();

        assertEq(mcd.dai().balanceOf(address(this)), 75 ether);
    }

    function test_arbitrum_relay() public {
        DaiAbstract l1Dai = mcd.dai();
        DaiAbstract l2Dai = DaiAbstract(0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1);
        ArbitrumDaiBridgeLike l2Bridge = ArbitrumDaiBridgeLike(0x467194771dAe2967Aef3ECbEDD3Bf9a310C76C65);
        l1Dai.setBalance(address(this), 100 ether);
        ArbitrumDaiBridgeLike bridge = ArbitrumDaiBridgeLike(mcd.chainlog().getAddress("ARBITRUM_DAI_BRIDGE"));

        // Transfer some DAI across the Arbitrum bridge
        l1Dai.approve(address(bridge), 100 ether);
        bridge.outboundTransfer{value:1 ether}(address(l1Dai), address(this), 100 ether, 1_000_000, 0, abi.encode(uint256(1 ether), bytes("")));

        // Message will be queued on L1, but not yet relayed
        assertEq(l1Dai.balanceOf(address(this)), 0);

        // Relay the message
        arbitrum.relayL1ToL2();

        // We are on Arbitrum fork with message relayed now
        assertEq(l2Dai.balanceOf(address(this)), 100 ether);

        // Queue up an L2 -> L1 message
        l2Dai.approve(address(l2Bridge), 100 ether);
        l2Bridge.outboundTransfer(address(l1Dai), address(this), 100 ether, "");
        assertEq(l2Dai.balanceOf(address(this)), 0);

        // Relay the message
        arbitrum.relayL2ToL1();

        // We are on Mainnet fork with message relayed now
        assertEq(mcd.dai().balanceOf(address(this)), 100 ether);

        // Go back and forth one more time
        mcd.dai().approve(address(bridge), 50 ether);
        bridge.outboundTransfer{value:1 ether}(address(l1Dai), address(this), 50 ether, 1_000_000, 0, abi.encode(uint256(1 ether), bytes("")));
        assertEq(mcd.dai().balanceOf(address(this)), 50 ether);

        arbitrum.relayL1ToL2();

        assertEq(l2Dai.balanceOf(address(this)), 50 ether);
        l2Dai.approve(address(l2Bridge), 25 ether);
        l2Bridge.outboundTransfer(address(l1Dai), address(this), 25 ether, "");
        assertEq(l2Dai.balanceOf(address(this)), 25 ether);

        arbitrum.relayL2ToL1();

        assertEq(mcd.dai().balanceOf(address(this)), 75 ether);
    }

}
