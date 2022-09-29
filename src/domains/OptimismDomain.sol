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

interface MessengerLike {
    function relayMessage(
        address _target,
        address _sender,
        bytes memory _message,
        uint256 _messageNonce
    ) external;
}

contract OptimismDomain is BridgedDomain {

    MessengerLike constant public l1messenger = MessengerLike(0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1);
    MessengerLike constant public l2messenger = MessengerLike(0x4200000000000000000000000000000000000007);

    bytes32 constant public SENT_MESSAGE_TOPIC = keccak256("SentMessage(address,address,bytes,uint256,uint256)");
    uint160 constant public OFFSET = uint160(0x1111000000000000000000000000000000001111);

    constructor(string memory _config, string memory _name, Domain _hostDomain) Domain(_config, _name) BridgedDomain(_hostDomain) {
        vm.recordLogs();
    }

    function relayFromHost() external override {
        selectFork();
        address malias;
        unchecked {
            malias = address(uint160(address(l1messenger)) + OFFSET);
        }

        // Read all L1 -> L2 messages and relay them under Optimism fork
        Vm.Log[] memory logs = vm.getRecordedLogs();
        for (uint256 i = 0; i < logs.length; i++) {
            Vm.Log memory log = logs[i];
            if (log.topics[0] == SENT_MESSAGE_TOPIC) {
                address target = address(uint160(uint256(log.topics[1])));
                (address sender, bytes memory message, uint40 nonce,) = abi.decode(log.data, (address, bytes, uint40, uint32));
                vm.startPrank(malias);
                l2messenger.relayMessage(target, sender, message, nonce);
                vm.stopPrank();
            }
        }
    }

    function relayToHost() external override {
        hostDomain.selectFork();

        // Read all L2 -> L1 messages and relay them under Primary fork
        // Note: We bypass the L1 messenger relay here because it's easier to not have to generate valid state roots / merkle proofs
        Vm.Log[] memory logs = vm.getRecordedLogs();
        for (uint256 i = 0; i < logs.length; i++) {
            Vm.Log memory log = logs[i];
            if (log.topics[0] == SENT_MESSAGE_TOPIC) {
                address target = address(uint160(uint256(log.topics[1])));
                (address sender, bytes memory message,,) = abi.decode(log.data, (address, bytes, uint40, uint32));
                // Set xDomainMessageSender
                vm.store(
                    address(l1messenger),
                    bytes32(uint256(204)),
                    bytes32(uint256(uint160(sender)))
                );
                vm.startPrank(address(l1messenger));
                (bool success, bytes memory response) = target.call(message);
                vm.stopPrank();
                vm.store(
                    address(l1messenger),
                    bytes32(uint256(204)),
                    bytes32(uint256(0))
                );
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
