// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2022 Dai Foundation
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
pragma solidity >=0.8.0;

import "forge-std/Vm.sol";

import {
    Domain,
    MainnetDomain
} from "./MainnetDomain.sol";
import { BridgedDomain } from "./BridgedDomain.sol";

interface InboxLike {
    function bridge() external view returns (address);
}

interface BridgeLike {
    function rollup() external view returns (address);
    function executeCall(
        address,
        uint256,
        bytes calldata
    ) external returns (bool, bytes memory);
    function setOutbox(address, bool) external;
}

contract ArbSysOverride {

    event SendTxToL1(address sender, address target, bytes data);

    function sendTxToL1(address target, bytes calldata message) external payable returns (uint256) {
        emit SendTxToL1(msg.sender, target, message);
        return 0;
    }

}

contract ArbitrumDomain is BridgedDomain {

    Domain public immutable primaryDomain;
    InboxLike public constant inbox = InboxLike(0x4Dbd4fc535Ac27206064B68FfCf827b0A60BAB3f);
    address public constant arbSys = 0x0000000000000000000000000000000000000064;
    BridgeLike public immutable bridge;
    address public l2ToL1Sender;

    bytes32 constant MESSAGE_DELIVERED_TOPIC = keccak256("MessageDelivered(uint256,bytes32,address,uint8,address,bytes32,uint256,uint64)");
    bytes32 constant SEND_TO_L1_TOPIC = keccak256("SendTxToL1(address,address,bytes)");

    constructor(string memory name, Domain _primaryDomain) Domain(name) {
        primaryDomain = _primaryDomain;
        bridge = BridgeLike(inbox.bridge());
        vm.recordLogs();

        // Make this contract a valid outbox
        address _rollup = bridge.rollup();
        vm.store(
            address(bridge),
            bytes32(uint256(8)),
            bytes32(uint256(uint160(address(this))))
        );
        bridge.setOutbox(address(this), true);
        vm.store(
            address(bridge),
            bytes32(uint256(8)),
            bytes32(uint256(uint160(_rollup)))
        );

        // Need to replace ArbSys contract with custom code to make it compatible with revm
        uint256 fork = vm.activeFork();
        makeActive();
        bytes memory bytecode = vm.getCode("ArbitrumDomain.sol:ArbSysOverride");
        address deployed;
        assembly {
            deployed := create(0, add(bytecode, 0x20), mload(bytecode))
        }
        vm.etch(arbSys, deployed.code);
        vm.selectFork(fork);
    }

    function parseData(bytes memory orig) private pure returns (address target, bytes memory message) {
        // FIXME - this is not robust enough, only handling messages of a specific format
        uint256 mlen;
        (,,target ,,,,,,,, mlen) = abi.decode(orig, (uint256, uint256, address, uint256, uint256, uint256, address, address, uint256, uint256, uint256));
        message = new bytes(mlen);
        for (uint256 i = 0; i < mlen; i++) {
            message[i] = orig[i + 352];
        }
    }

    function relayL1ToL2() external override {
        makeActive();

        // Read all L1 -> L2 messages and relay them under Arbitrum fork
        Vm.Log[] memory logs = vm.getRecordedLogs();
        for (uint256 i = 0; i < logs.length; i++) {
            Vm.Log memory log = logs[i];
            if (log.topics[0] == MESSAGE_DELIVERED_TOPIC) {
                // We need both the current event and the one that follows for all the relevant data
                Vm.Log memory logWithData = logs[i + 1];
                (,, address sender,,,) = abi.decode(log.data, (address, uint8, address, bytes32, uint256, uint64));
                (address target, bytes memory message) = parseData(logWithData.data);
                vm.startPrank(sender);
                (bool success, bytes memory response) = target.call(message);
                vm.stopPrank();
                if (!success) {
                    string memory rmessage;
                    assembly {
                        let size := mload(add(response, 0x44))
                        rmessage := mload(0x40)
                        mstore(rmessage, size)
                        mstore(0x40, add(rmessage, and(add(add(size, 0x20), 0x1f), not(0x1f))))
                        returndatacopy(add(rmessage, 0x20), 0x44, size)
                    }
                    revert(rmessage);
                }
            }
        }
    }

    function relayL2ToL1() external override {
        primaryDomain.makeActive();

        // Read all L2 -> L1 messages and relay them under Primary fork
        Vm.Log[] memory logs = vm.getRecordedLogs();
        for (uint256 i = 0; i < logs.length; i++) {
            Vm.Log memory log = logs[i];
            if (log.topics[0] == SEND_TO_L1_TOPIC) {
                (address sender, address target, bytes memory message) = abi.decode(log.data, (address, address, bytes));
                l2ToL1Sender = sender;
                (bool success, bytes memory response) = bridge.executeCall(target, 0, message);
                if (!success) {
                    string memory rmessage;
                    assembly {
                        let size := mload(add(response, 0x44))
                        rmessage := mload(0x40)
                        mstore(rmessage, size)
                        mstore(0x40, add(rmessage, and(add(add(size, 0x20), 0x1f), not(0x1f))))
                        returndatacopy(add(rmessage, 0x20), 0x44, size)
                    }
                    revert(rmessage);
                }
            }
        }
    }
    
}
