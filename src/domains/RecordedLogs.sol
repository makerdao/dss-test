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
import { ScriptTools } from "../ScriptTools.sol";

library RecordedLogs {
    Vm internal constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function getLogs() internal returns (Vm.Log[] memory) {
        string memory _logs = vm.serializeUint("LOG", "a", 0); // this is the only way to get the logs from the memory object
        uint256 count = ScriptTools.eq(_logs, '{"a":0}') ? 0 : abi.decode(vm.parseJson(_logs, "count"), (uint256));

        Vm.Log[] memory newLogs = vm.getRecordedLogs();
        Vm.Log[] memory logs = new Vm.Log[](count + newLogs.length);
        for (uint256 i = 0; i < count; i++) {
            bytes memory rawData = vm.parseJson(_logs, string(abi.encodePacked(vm.toString(i), "_", "data")));
            if (rawData.length > 64) {
                // We only need the data content itself, so we have to skip the first 64 bytes
                // data of logs that are less than a word will not be saved as bytes, so won't have the 64 bytes prefix
                // as those logs are not bridge message relaying related, we directly ignore their content
                bytes memory data = new bytes(rawData.length - 64);
                for (uint256 j = 0; j < data.length; j++) {
                    data[j] = rawData[j + 64];
                }
                logs[i].data = data;
            }
            logs[i].topics  = abi.decode(vm.parseJson(_logs, string(abi.encodePacked(vm.toString(i), "_", "topics"))), (bytes32[]));
            // emitter is not needed, at least in the actual domains implementations
            // logs[i].emitter = abi.decode(vm.parseJson(_logs, string(abi.encodePacked(vm.toString(i), "_", "emitter"))), (address));
        }

        for (uint256 i = 0; i < newLogs.length; i++) {
            vm.serializeBytes("LOG", string(abi.encodePacked(vm.toString(count), "_", "data")), logs[count].data = newLogs[i].data);
            vm.serializeBytes32("LOG", string(abi.encodePacked(vm.toString(count), "_", "topics")), logs[count].topics = newLogs[i].topics);
            // vm.serializeAddress("LOG", string(abi.encodePacked(vm.toString(count), "_", "emitter")), logs[count].emitter = newLogs[i].emitter);
            count++;
        }
        vm.serializeUint("LOG", "count", count);

        return logs;
    }
}
