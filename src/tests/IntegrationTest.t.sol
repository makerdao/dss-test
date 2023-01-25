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

import "../DssTest.sol";
import "../domains/RootDomain.sol";
import "../domains/OptimismDomain.sol";
import "../domains/ArbitrumDomain.sol";

interface OptimismDaiBridgeLike {
    function depositERC20To(address, address, address, uint256, uint32, bytes calldata) external;
    function withdrawTo(address, address, uint256, uint32, bytes calldata) external;
    function l2Token() external view returns (address);
    function l2DAITokenBridge() external view returns (address);
}

interface ArbitrumDaiBridgeLike {
    function l1Dai() external view returns (address);
    function outboundTransfer(address, address, uint256, uint256, uint256, bytes calldata) external payable;
    function outboundTransfer(address, address, uint256, bytes calldata) external;
    function l2Dai() external view returns (address);
    function l2Counterpart() external view returns (address);
}

contract IntegrationTest is DssTest {

    using GodMode for *;
    using MCD for DssInstance;

    string config;
    RootDomain rootDomain;
    DssInstance dss;
    DssIlkInstance ethA;

    MCDUser user1;
    MCDUser user2;
    MCDUser user3;

    OptimismDomain optimism;
    ArbitrumDomain arbitrum;

    function setUp() public virtual {
        config = ScriptTools.readInput("integration");

        rootDomain = new RootDomain(config, getRelativeChain("mainnet"));
        rootDomain.selectFork();
        rootDomain.loadDssFromChainlog();
        dss = rootDomain.dss(); // For ease of access
        ethA = dss.getIlk("ETH", "A");

        user1 = dss.newUser();
        user2 = dss.newUser();
        user3 = dss.newUser();

        optimism = new OptimismDomain(config, getRelativeChain("optimism"), rootDomain);
        arbitrum = new ArbitrumDomain(config, getRelativeChain("arbitrum_one"), rootDomain);
    }

    function test_give_tokens() public {
        dss.dai.setBalance(address(this), 100 ether);
        assertEq(dss.dai.balanceOf(address(this)), 100 ether);
    }

    function test_create_liquidation() public {
        uint256 prevKicks = ethA.clip.kicks();
        user1.createAuction(ethA.join, 100 ether);
        assertEq(ethA.clip.kicks(), prevKicks + 1);
    }

    function test_auth() public {
        // Test that the vesting contract has proper auth setup
        // Note: can only test against newer style contracts that don't use LibNote
        checkAuth(dss.chainlog.getAddress("MCD_VEST_DAI"), "DssVest");
    }

    function test_file_uint() public {
        // Test that the end contract has proper file
        // Note: can only test against newer style contracts that don't use LibNote
        checkFileUint(dss.chainlog.getAddress("MCD_END"), "End", ["wait"]);
    }

    function test_file_address() public {
        // Test that the end contract has proper file
        // Note: can only test against newer style contracts that don't use LibNote
        checkFileAddress(dss.chainlog.getAddress("MCD_END"), "End", ["vat", "cat", "dog", "vow", "pot", "spot"]);
    }

    function test_optimism_relay() public {
        OptimismDaiBridgeLike bridge = OptimismDaiBridgeLike(dss.chainlog.getAddress("OPTIMISM_DAI_BRIDGE"));
        DaiAbstract l2Dai = DaiAbstract(bridge.l2Token());
        OptimismDaiBridgeLike l2Bridge = OptimismDaiBridgeLike(bridge.l2DAITokenBridge());
        dss.dai.setBalance(address(this), 100 ether);

        // Transfer some DAI across the Optimism bridge
        dss.dai.approve(address(bridge), 100 ether);
        bridge.depositERC20To(address(dss.dai), address(l2Dai), address(this), 100 ether, 1_000_000, "");

        // Message will be queued on L1, but not yet relayed
        assertEq(dss.dai.balanceOf(address(this)), 0);

        // Relay the message
        optimism.relayFromHost(true);

        // We are on Optimism fork with message relayed now
        assertEq(l2Dai.balanceOf(address(this)), 100 ether);

        // Queue up an L2 -> L1 message
        l2Dai.approve(address(l2Bridge), 100 ether);
        l2Bridge.withdrawTo(address(l2Dai), address(this), 100 ether, 1_000_000, "");
        assertEq(l2Dai.balanceOf(address(this)), 0);

        // Relay the message
        optimism.relayToHost(true);

        // We are on Mainnet fork with message relayed now
        assertEq(dss.dai.balanceOf(address(this)), 100 ether);

        // Go back and forth one more time
        dss.dai.approve(address(bridge), 50 ether);
        bridge.depositERC20To(address(dss.dai), address(l2Dai), address(this), 50 ether, 1_000_000, "");
        assertEq(dss.dai.balanceOf(address(this)), 50 ether);

        optimism.relayFromHost(true);

        assertEq(l2Dai.balanceOf(address(this)), 50 ether);
        l2Dai.approve(address(l2Bridge), 25 ether);
        l2Bridge.withdrawTo(address(l2Dai), address(this), 25 ether, 1_000_000, "");
        assertEq(l2Dai.balanceOf(address(this)), 25 ether);

        optimism.relayToHost(true);

        assertEq(dss.dai.balanceOf(address(this)), 75 ether);
    }

    function test_arbitrum_relay() public {
        ArbitrumDaiBridgeLike bridge = ArbitrumDaiBridgeLike(dss.chainlog.getAddress("ARBITRUM_DAI_BRIDGE"));
        DaiAbstract l1Dai = dss.dai;
        DaiAbstract l2Dai = DaiAbstract(bridge.l2Dai());
        ArbitrumDaiBridgeLike l2Bridge = ArbitrumDaiBridgeLike(bridge.l2Counterpart());
        l1Dai.setBalance(address(this), 100 ether);

        // Transfer some DAI across the Arbitrum bridge
        l1Dai.approve(address(bridge), 100 ether);
        bridge.outboundTransfer{value:1 ether}(address(l1Dai), address(this), 100 ether, 1_000_000, 0, abi.encode(uint256(1 ether), bytes("")));

        // Message will be queued on L1, but not yet relayed
        assertEq(l1Dai.balanceOf(address(this)), 0);

        // Relay the message
        arbitrum.relayFromHost(true);

        // We are on Arbitrum fork with message relayed now
        assertEq(l2Dai.balanceOf(address(this)), 100 ether);

        // Queue up an L2 -> L1 message
        l2Dai.approve(address(l2Bridge), 100 ether);
        l2Bridge.outboundTransfer(address(l1Dai), address(this), 100 ether, "");
        assertEq(l2Dai.balanceOf(address(this)), 0);

        // Relay the message
        arbitrum.relayToHost(true);

        // We are on Mainnet fork with message relayed now
        assertEq(dss.dai.balanceOf(address(this)), 100 ether);

        // Go back and forth one more time
        dss.dai.approve(address(bridge), 50 ether);
        bridge.outboundTransfer{value:1 ether}(address(l1Dai), address(this), 50 ether, 1_000_000, 0, abi.encode(uint256(1 ether), bytes("")));
        assertEq(dss.dai.balanceOf(address(this)), 50 ether);

        arbitrum.relayFromHost(true);

        assertEq(l2Dai.balanceOf(address(this)), 50 ether);
        l2Dai.approve(address(l2Bridge), 25 ether);
        l2Bridge.outboundTransfer(address(l1Dai), address(this), 25 ether, "");
        assertEq(l2Dai.balanceOf(address(this)), 25 ether);

        arbitrum.relayToHost(true);

        assertEq(dss.dai.balanceOf(address(this)), 75 ether);
    }

}
