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
pragma solidity >=0.8.0;

import "./Domain.sol";
import {MainnetDomain} from "./MainnetDomain.sol";

interface MessengerLike {
    function xDomainMessageSender() external view returns (address);
    function sendMessage(
        address _target,
        bytes memory _message,
        uint32 _gasLimit
    ) external;
    function relayMessage(
        address _target,
        address _sender,
        bytes memory _message,
        uint256 _messageNonce
    ) external;
}

contract OptimismDomain is Domain {

    MainnetDomain public mainnet;
    MessengerLike public l1messenger;
    MessengerLike public l2messenger;
    uint256 lastRelayedL1ToL2;
    uint256 lastRelayedL2ToL1;

    bytes32 constant SENT_MESSAGE_TOPIC = keccak256("SentMessage(address,address,bytes,uint256,uint256)");
    uint160 constant OFFSET = uint160(0x1111000000000000000000000000000000001111);

    constructor(MainnetDomain _mainnet) Domain("optimism") {
        mainnet = _mainnet;
        l1messenger = MessengerLike(0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1);
        l2messenger = MessengerLike(0x4200000000000000000000000000000000000007);
        vm.recordLogs();
    }

    function relayL1ToL2() external {
        makeActive();
        address malias;
        unchecked {
            malias = address(uint160(address(l1messenger)) + OFFSET);
        }

        // Read all L1 -> L2 messages and relay them under Optimism fork
        Vm.Log[] memory logs = vm.getRecordedLogs();
        for (uint256 i = lastRelayedL1ToL2; i < logs.length; i++) {
            Vm.Log memory log = logs[i];
            if (log.topics[0] == SENT_MESSAGE_TOPIC) {
                (address target, address sender, bytes memory message, uint40 nonce,) = abi.decode(log.data, (address, address, bytes, uint40, uint32));
                vm.startPrank(malias);
                l2messenger.relayMessage(target, sender, message, nonce);
                vm.stopPrank();
            }
        }
        lastRelayedL1ToL2 = logs.length;
    }

    function relayL2ToL1() external {
        mainnet.makeActive();
    }
    
}
