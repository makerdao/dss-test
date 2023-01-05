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

import { Domain, BridgedDomain } from "./BridgedDomain.sol";

contract ZKSyncDomain is BridgedDomain {

    address public immutable zkSyncMailbox;
    address public immutable l1MessengerContract;

    bytes32 constant SENT_MESSAGE_TOPIC = keccak256("SentMessage(address,address,bytes,uint256,uint256)");

    constructor(string memory _config, string memory _name, Domain _hostDomain) Domain(_config, _name) BridgedDomain(_hostDomain) {
        zkSyncMailbox = MessengerLike(readConfigAddress("zkSyncMailbox"));
        l1MessengerContract = MessengerLike(readConfigAddress("l1MessengerContract"));
        vm.recordLogs();
    }

    function relayFromHost(bool switchToGuest) external override {
        selectFork();
        address malias;
        unchecked {
            malias = address(uint160(address(l1Messenger)) + OFFSET);
        }

        // Read all L1 -> L2 messages and relay them this fork
        Vm.Log[] memory logs = vm.getRecordedLogs();
        for (uint256 i = 0; i < logs.length; i++) {
            Vm.Log memory log = logs[i];
            if (log.topics[0] == SENT_MESSAGE_TOPIC) {
                // TODO
            }
        }

        if (!switchToGuest) {
            hostDomain.selectFork();
        }
    }

    function relayToHost(bool switchToHost) external override {
        hostDomain.selectFork();

        // Read all L2 -> L1 messages and relay them under host fork
        Vm.Log[] memory logs = vm.getRecordedLogs();
        for (uint256 i = 0; i < logs.length; i++) {
            Vm.Log memory log = logs[i];
            if (log.topics[0] == SENT_MESSAGE_TOPIC) {
                // TODO
            }
        }

        if (!switchToHost) {
            selectFork();
        }
    }
    
}
