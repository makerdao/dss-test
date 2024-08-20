// SPDX-FileCopyrightText: © 2022 Dai Foundation <www.daifoundation.org>
// SPDX-License-Identifier: AGPL-3.0-or-later
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

import { RecordedLogs } from "./RecordedLogs.sol";
import { Domain, BridgedDomain } from "./BridgedDomain.sol";
import { stdStorage, StdStorage } from "forge-std/Test.sol";        
import { StdChains } from "forge-std/StdChains.sol";

interface MessengerLike {
    function sendMessage(
        address target,
        bytes memory message,
        uint32 gasLimit
    ) external;
    function relayMessage(
        uint256 _nonce,
        address _sender,
        address _target,
        uint256 _value,
        uint256 _minGasLimit,
        bytes calldata _message
    ) external payable;
}

interface L1MessengerLike {
    function portal() external returns (address);
}

contract OptimismDomain is BridgedDomain {
    using stdStorage for StdStorage;

    MessengerLike public immutable l1Messenger;
    MessengerLike public immutable l2Messenger;

    bytes32 constant SENT_MESSAGE_TOPIC = keccak256("SentMessage(address,address,bytes,uint256,uint256)");
    uint160 constant OFFSET = uint160(0x1111000000000000000000000000000000001111);

    StdStorage internal stdstore;

    uint256 internal lastFromHostLogIndex;
    uint256 internal lastToHostLogIndex;

    constructor(string memory _config, StdChains.Chain memory _chain, Domain _hostDomain) Domain(_config, _chain) BridgedDomain(_hostDomain) {
        l1Messenger = MessengerLike(readConfigAddress("l1Messenger"));
        l2Messenger = MessengerLike(readConfigAddress("l2Messenger"));
        vm.recordLogs();
    }

    function isGoerli() private view returns (bool) {
        return keccak256(bytes(details().chainAlias)) == keccak256(bytes("optimism_goerli"));
    }

    function relayFromHost(bool switchToGuest) external override {
        selectFork();
        address malias;
        unchecked {
            malias = address(uint160(address(l1Messenger)) + OFFSET);
        }

        // Read all L1 -> L2 messages and relay them under Optimism fork
        Vm.Log[] memory logs = RecordedLogs.getLogs();
        for (; lastFromHostLogIndex < logs.length; lastFromHostLogIndex++) {
            Vm.Log memory log = logs[lastFromHostLogIndex];
            if (log.topics[0] == SENT_MESSAGE_TOPIC && log.emitter == address(l1Messenger)) {
                address target = address(uint160(uint256(log.topics[1])));
                (address sender, bytes memory message, uint256 nonce, uint256 gasLimit) = abi.decode(log.data, (address, bytes, uint256, uint256));
                vm.prank(malias);
                l2Messenger.relayMessage(nonce, sender, target, 0, gasLimit, message);
            }
        }

        if (!switchToGuest) {
            hostDomain.selectFork();
        }
    }

    function relayToHost(bool switchToHost) external override {
        hostDomain.selectFork();
        address portal = L1MessengerLike(address(l1Messenger)).portal();

        // Read all L2 -> L1 messages and relay them under Primary fork
        Vm.Log[] memory logs = RecordedLogs.getLogs();
        for (; lastToHostLogIndex < logs.length; lastToHostLogIndex++) {
            Vm.Log memory log = logs[lastToHostLogIndex];
            if (log.topics[0] == SENT_MESSAGE_TOPIC && log.emitter == address(l2Messenger)) {
                address target = address(uint160(uint256(log.topics[1])));
                (address sender, bytes memory message, uint256 nonce, uint256 gasLimit) = abi.decode(log.data, (address, bytes, uint256, uint256));
                stdstore.target(portal).sig("l2Sender()").checked_write(address(l2Messenger));
                vm.prank(portal);
                l1Messenger.relayMessage(nonce, sender, target, 0, gasLimit, message);
            }
        }

        if (!switchToHost) {
            selectFork();
        }
    }
    
}
