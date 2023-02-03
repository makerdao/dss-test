// SPDX-FileCopyrightText: © 2023 Dai Foundation <www.daifoundation.org>
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

import { Vm } from "forge-std/Vm.sol";

library RecordedLogs {
    Vm internal constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function _write(string memory json) private {
        vm.writeJson(json, string(abi.encodePacked(vm.projectRoot(), "/cache/logs", _uintToString(uint256(bytes32(msg.sig))), ".json")));
    }

    function _uintToString(uint256 v) private pure returns (string memory str) {
        if (v == 0) {
            return "0";
        }
        uint256 j = v;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = v;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        str = string(bstr);
    }

    function initFile() internal {
        _write("");
        vm.removeFile(string(abi.encodePacked(vm.projectRoot(), "/cache/logs", _uintToString(uint256(bytes32(msg.sig))), ".json")));
        string memory json = vm.serializeUint("LOG", "count", 0);
        _write(json);
    }

    function getLogs() internal returns (Vm.Log[] memory) {
        // emitter is not needed at least for now
        string memory _logs = string(vm.readFile(string(abi.encodePacked(vm.projectRoot(), "/cache/logs", _uintToString(uint256(bytes32(msg.sig))), ".json"))));
        uint256 count = abi.decode(vm.parseJson(_logs, "count"), (uint256));

        Vm.Log[] memory newLogs = vm.getRecordedLogs();
        Vm.Log[] memory logs = new Vm.Log[](count + newLogs.length);
        for (uint256 i = 0; i < count; i++) {
            bytes memory rawData = vm.parseJson(_logs, string(abi.encodePacked(_uintToString(i), "_", "data")));
            if (rawData.length > 64) {
                // We only care about the data field, so we can skip the first 64 bytes
                // logs that are actually less than 64 bytes are not relevant as message passing
                bytes memory data = new bytes(rawData.length - 64);
                for (uint256 j = 0; j < data.length; j++) {
                    data[j] = rawData[j + 64];
                }
                logs[i].data = data;
            }
            logs[i].topics  = abi.decode(vm.parseJson(_logs, string(abi.encodePacked(_uintToString(i), "_", "topics"))), (bytes32[]));
            // logs[i].emitter = abi.decode(vm.parseJson(_logs, string(abi.encodePacked(_uintToString(i), "_", "emitter"))), (address));
        }

        for (uint256 i = 0; i < newLogs.length; i++) {
            vm.serializeBytes("LOG", string(abi.encodePacked(_uintToString(count), "_", "data")), newLogs[i].data);
            vm.serializeBytes32("LOG", string(abi.encodePacked(_uintToString(count), "_", "topics")), newLogs[i].topics);
            // vm.serializeAddress("LOG", string(abi.encodePacked(_uintToString(count), "_", "emitter")), newLogs[i].emitter);
            logs[count].data = newLogs[i].data;
            logs[count].topics  = newLogs[i].topics;
            // logs[count].emitter = newLogs[i].emitter;
            count++;
        }
        _write(vm.serializeUint("LOG", "count", count));

        return logs;
    }
}
