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

contract RecordedLogsStorage {

    Vm.Log[] private _logs;

    constructor() {
    }

    function addLogs(Vm.Log[] memory newLogs) public {
        for (uint256 i = 0; i < newLogs.length; i++) {
            _logs.push(newLogs[i]);
        }
    }

    function getLogs() public view returns (Vm.Log[] memory) {
        return _logs;
    }

}

library RecordedLogs {

    RecordedLogsStorage public constant STORAGE = RecordedLogsStorage(address(uint160(uint256(keccak256("RECORDED_LOGS_STORAGE")))));

    Vm internal constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function isContract(address _addr) private view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function checkInitialized() private {
        if (!isContract(address(STORAGE))) {
            bytes memory bytecode = vm.getCode("RecordedLogs.sol:RecordedLogsStorage");
            address deployed;
            assembly {
                deployed := create(0, add(bytecode, 0x20), mload(bytecode))
            }
            vm.etch(address(STORAGE), deployed.code);
            vm.makePersistent(address(STORAGE));
        }
    }

    function getLogs() internal returns (Vm.Log[] memory) {
        checkInitialized();
        STORAGE.addLogs(vm.getRecordedLogs());
        return STORAGE.getLogs();
    }

}
