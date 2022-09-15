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

interface InboxLike {
    function bridge() external view returns (address);
}

interface BridgeLike {
    function activeOutbox() external view returns (address);
}

interface OutboxLike {
    function l2ToL1Sender() external view returns (address);
}

contract ArbSysOverride {

    event SendTxToL1(address sender, address target, bytes data);

    function sendTxToL1(address target, bytes calldata message) external {
        emit SendTxToL1(msg.sender, target, message);
    }

}

contract ArbitrumDomain is Domain {

    Domain public primaryDomain;
    InboxLike public l1messenger;
    //MessengerLike public l2messenger;

    bytes32 constant MESSAGE_DELIVERED_TOPIC = keccak256("MessageDelivered(uint256,bytes32,address,uint8,address,bytes32,uint256,uint64)");
    uint160 constant OFFSET = uint160(0x1111000000000000000000000000000000001111);

    event Test(bytes);
    event Num(uint256);
    event Addr(address);
    event Bool(bool);

    constructor(Domain _primaryDomain) Domain("arbitrum") {
        primaryDomain = _primaryDomain;
        l1messenger = InboxLike(0x4Dbd4fc535Ac27206064B68FfCf827b0A60BAB3f);
        //l2messenger = MessengerLike(0x0000000000000000000000000000000000000064);
        vm.recordLogs();

        // Need to replace ArbSys contract with custom code to make it compatible with revm
        uint256 fork = vm.activeFork();
        makeActive();
        vm.etch(0x0000000000000000000000000000000000000064, vm.getCode("ArbitrumDomain.sol:ArbSysOverride"));
        vm.selectFork(fork);
    }

    function parseData(bytes memory orig) private  returns (address target, bytes memory message) {
        // FIXME - this is not robust enough, only handling messages of a specific format
        uint256 mlen;
        (,,target ,,,,,,,, mlen) = abi.decode(orig, (uint256, uint256, address, uint256, uint256, uint256, address, address, uint256, uint256, uint256));
        message = new bytes(mlen);
        for (uint256 i = 0; i < mlen; i++) {
            message[i] = orig[i + 352];
        }
        emit Test(message);
    }

    function relayL1ToL2() external {
        //revert("shows error msg");
        makeActive();
        revert("doesn't show error msg");

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

    function relayL2ToL1() external {
        primaryDomain.makeActive();

        // Read all L2 -> L1 messages and relay them under Primary fork
        // Note: We bypass the L1 messenger relay here because it's easier to not have to generate valid state roots / merkle proofs
        Vm.Log[] memory logs = vm.getRecordedLogs();
        for (uint256 i = 0; i < logs.length; i++) {
            Vm.Log memory log = logs[i];
            if (log.topics[0] == MESSAGE_DELIVERED_TOPIC) {
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
