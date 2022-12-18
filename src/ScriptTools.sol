// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2017 DappHub, LLC
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

import { VmSafe } from "forge-std/Vm.sol";
import { stdJson } from "forge-std/StdJson.sol";
import { console } from "forge-std/console.sol";

/** 
 * @title Script Tools
 * @dev Contains opinionated tools used in scripts.
 */
library ScriptTools {

    VmSafe private constant vm = VmSafe(address(uint160(uint256(keccak256("hevm cheat code")))));
    
    string internal constant DEFAULT_DELIMITER = ",";
    string internal constant DELIMITER_OVERRIDE = "DSSTEST_ARRAY_DELIMITER";

    function readInput(string memory input) internal view returns (string memory) {
        string memory root = vm.projectRoot();
        string memory chainInputFolder = string(abi.encodePacked("/script/input/", vm.toString(block.chainid), "/"));
        return vm.readFile(string(abi.encodePacked(root, chainInputFolder, input, ".json")));
    }

    /// @dev It's common to define strings as bytes32 (such as for ilks)
    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    /**
     * @dev Used to export important contracts to higher level deploy scripts.
     *      Note waiting on forge updates to support better exporting of contracts.
     *      For now we just log to stdout.
     */
    function logContract(string memory name, address addr) internal view {
        console.log(string(abi.encodePacked("DSSTEST_EXPORT_", name, "=", vm.toString(addr))));
    }

    // Read config variable, but allow for an environment variable override

    function readUint(string memory json, string memory key, string memory envKey) internal returns (uint256) {
        return vm.envOr(envKey, stdJson.readUint(json, key));
    }

    function readUintArray(string memory json, string memory key, string memory envKey) internal returns (uint256[] memory) {
        return vm.envOr(envKey, vm.envOr(DELIMITER_OVERRIDE, DEFAULT_DELIMITER), stdJson.readUintArray(json, key));
    }

    function readInt(string memory json, string memory key, string memory envKey) internal returns (int256) {
        return vm.envOr(envKey, stdJson.readInt(json, key));
    }

    function readIntArray(string memory json, string memory key, string memory envKey) internal returns (int256[] memory) {
        return vm.envOr(envKey, vm.envOr(DELIMITER_OVERRIDE, DEFAULT_DELIMITER), stdJson.readIntArray(json, key));
    }

    function readBytes32(string memory json, string memory key, string memory envKey) internal returns (bytes32) {
        return vm.envOr(envKey, stdJson.readBytes32(json, key));
    }

    function readBytes32Array(string memory json, string memory key, string memory envKey) internal returns (bytes32[] memory) {
        return vm.envOr(envKey, vm.envOr(DELIMITER_OVERRIDE, DEFAULT_DELIMITER), stdJson.readBytes32Array(json, key));
    }

    function readString(string memory json, string memory key, string memory envKey) internal returns (string memory) {
        return vm.envOr(envKey, stdJson.readString(json, key));
    }

    function readStringArray(string memory json, string memory key, string memory envKey) internal returns (string[] memory) {
        return vm.envOr(envKey, vm.envOr(DELIMITER_OVERRIDE, DEFAULT_DELIMITER), stdJson.readStringArray(json, key));
    }

    function readAddress(string memory json, string memory key, string memory envKey) internal returns (address) {
        return vm.envOr(envKey, stdJson.readAddress(json, key));
    }

    function readAddressArray(string memory json, string memory key, string memory envKey) internal returns (address[] memory) {
        return vm.envOr(envKey, vm.envOr(DELIMITER_OVERRIDE, DEFAULT_DELIMITER), stdJson.readAddressArray(json, key));
    }

    function readBool(string memory json, string memory key, string memory envKey) internal returns (bool) {
        return vm.envOr(envKey, stdJson.readBool(json, key));
    }

    function readBoolArray(string memory json, string memory key, string memory envKey) internal returns (bool[] memory) {
        return vm.envOr(envKey, vm.envOr(DELIMITER_OVERRIDE, DEFAULT_DELIMITER), stdJson.readBoolArray(json, key));
    }

    function readBytes(string memory json, string memory key, string memory envKey) internal returns (bytes memory) {
        return vm.envOr(envKey, stdJson.readBytes(json, key));
    }

    function readBytesArray(string memory json, string memory key, string memory envKey) internal returns (bytes[] memory) {
        return vm.envOr(envKey, vm.envOr(DELIMITER_OVERRIDE, DEFAULT_DELIMITER), stdJson.readBytesArray(json, key));
    }

}
