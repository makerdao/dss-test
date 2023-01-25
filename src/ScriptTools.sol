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

import { VmSafe } from "forge-std/Vm.sol";
import { stdJson } from "forge-std/StdJson.sol";

import { WardsAbstract } from "dss-interfaces/Interfaces.sol";

/** 
 * @title Script Tools
 * @dev Contains opinionated tools used in scripts.
 */
library ScriptTools {

    VmSafe private constant vm = VmSafe(address(uint160(uint256(keccak256("hevm cheat code")))));
    
    string internal constant DEFAULT_DELIMITER = ",";
    string internal constant DELIMITER_OVERRIDE = "DSSTEST_ARRAY_DELIMITER";
    string internal constant EXPORT_JSON_KEY = "EXPORTS";

    function getRootChainId() internal view returns (uint256) {
        return vm.envUint("FOUNDRY_ROOT_CHAINID");
    }

    function readInput(string memory name) internal view returns (string memory) {
        string memory root = vm.projectRoot();
        string memory chainInputFolder = string(abi.encodePacked("/script/input/", vm.toString(getRootChainId()), "/"));
        return vm.readFile(string(abi.encodePacked(root, chainInputFolder, name, ".json")));
    }

    function readOutput(string memory name) internal view returns (string memory) {
        string memory root = vm.projectRoot();
        string memory chainOutputFolder = string(abi.encodePacked("/script/output/", vm.toString(getRootChainId()), "/"));
        return vm.readFile(string(abi.encodePacked(root, chainOutputFolder, name, ".json")));
    }
    
    /**
     * @notice Use standard environment variables to load config.
     * @dev Will first check FOUNDRY_SCRIPT_CONFIG_TEXT for raw json text.
     *      Falls back to FOUNDRY_SCRIPT_CONFIG for a standard file definition.
     *      Finally will fall back to the given string `name`.
     * @param name The default config file to load if no environment variables are set.
     * @return config The raw json text of the config.
     */
    function loadConfig(string memory name) internal returns (string memory config) {
        config = vm.envOr("FOUNDRY_SCRIPT_CONFIG_TEXT", readInput(vm.envOr("FOUNDRY_SCRIPT_CONFIG", name)));
    }
    
    /**
     * @notice Use standard environment variables to load config.
     * @dev Will first check FOUNDRY_SCRIPT_CONFIG_TEXT for raw json text.
     *      Falls back to FOUNDRY_SCRIPT_CONFIG for a standard file definition.
     *      Finally will revert if no environment variables are set.
     * @return config The raw json text of the config.
     */
    function loadConfig() internal returns (string memory config) {
        config = vm.envOr("FOUNDRY_SCRIPT_CONFIG_TEXT", readInput(vm.envString("FOUNDRY_SCRIPT_CONFIG")));
    }

    /**
     * @notice It's common to define strings as bytes32 (such as for ilks)
     */
    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory emptyStringTest = bytes(source);
        if (emptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    /**
     * @notice Convert an ilk to a chainlog key by replacing all dashes with underscores.
     *         Ex) Convert "ETH-A" to "ETH_A"
     */
    function ilkToChainlogFormat(bytes32 ilk) internal pure returns (string memory) {
        uint256 len = 0;
        for (; len < 32; len++) {
            if (uint8(ilk[len]) == 0x00) break;
        }
        bytes memory result = new bytes(len);
        for (uint256 i = 0; i < len; i++) {
            uint8 b = uint8(ilk[i]);
            if (b == 0x2d) result[i] = bytes1(0x5f);
            else result[i] = bytes1(b);
        }
        return string(result);
    }

    function eq(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }

    /**
     * @notice Used to export important contracts to higher level deploy scripts.
     *         Note waiting on Foundry to have better primatives, but roll our own for now.
     */
    function exportContract(string memory name, string memory label, address addr) internal {
        string memory json = vm.serializeAddress(EXPORT_JSON_KEY, label, addr);
        string memory root = vm.projectRoot();
        string memory chainOutputFolder = string(abi.encodePacked("/script/output/", vm.toString(getRootChainId()), "/"));
        vm.writeJson(json, string(abi.encodePacked(root, chainOutputFolder, name, "-", vm.toString(block.timestamp), ".json")));
        if (!vm.envOr("FOUNDRY_EXPORTS_NO_OVERWRITE_LATEST", false)) {
            vm.writeJson(json, string(abi.encodePacked(root, chainOutputFolder, name, "-latest.json")));
        }
    }

    function switchOwner(address base, address deployer, address newOwner) internal {
        if (deployer == newOwner) return;
        require(WardsAbstract(base).wards(deployer) == 1, "deployer-not-authed");
        WardsAbstract(base).rely(newOwner);
        WardsAbstract(base).deny(deployer);
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
