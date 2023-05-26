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

import "forge-std/Test.sol";

import { ScriptTools } from "./ScriptTools.sol";
import {
    GodMode,
    MCD,
    MCDUser,
    DssInstance,
    DssIlkInstance
} from "./MCD.sol";

interface AuthLike {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
}

interface FileLike is AuthLike {
    function file(bytes32, uint256) external;
    function file(bytes32, address) external;
    function file(bytes32, string memory) external;
}

abstract contract DssTest is Test {

    uint256 constant WAD = 10 ** 18;
    uint256 constant RAY = 10 ** 27;
    uint256 constant RAD = 10 ** 45;
    uint256 constant BPS = 10 ** 4;

    uint256 constant THOUSAND = 10 ** 3;
    uint256 constant MILLION = 10 ** 6;
    uint256 constant BILLION = 10 ** 9;

    address constant TEST_ADDRESS = address(bytes20(uint160(uint256(keccak256('random test address')))));

    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event File(bytes32 indexed what, uint256 data);
    event File(bytes32 indexed what, address data);
    event File(bytes32 indexed what, string data);

    /**
     * @notice Takes the root chain into account when finding relative chains.
     *         Ex. if the root chain id is 5 then "optimism" will convert to "optimism_goerli", etc
     */
    function getRelativeChain(string memory name) internal returns (StdChains.Chain memory) {
        if (ScriptTools.getRootChainId() == 5) {
            // Do Goerli translations
            if (ScriptTools.eq(name, "mainnet")) name = "goerli";
            else if (ScriptTools.eq(name, "optimism")) name = "optimism_goerli";
            else if (ScriptTools.eq(name, "arbitrum_one")) name = "arbitrum_one_goerli";
        }

        return getChain(name);
    }

    function assertRevert(address target, bytes memory data, string memory expectedMessage) internal {
        assertRevert(target, data, 0, expectedMessage);
    }

    function assertRevert(address target, bytes memory data, uint256 value, string memory expectedMessage) internal {
        bool succeeded;
        bytes memory response;
        (succeeded, response) = target.call{value:value}(data);
        if (succeeded) {
            emit log("Error: call not reverted");
            fail();
        } else {
            string memory message;
            assembly {
                let size := mload(add(response, 0x44))
                message := mload(0x40)
                mstore(message, size)
                mstore(0x40, add(message, and(add(add(size, 0x20), 0x1f), not(0x1f))))
                returndatacopy(add(message, 0x20), 0x44, size)
            }
            if (keccak256(abi.encodePacked(message)) != keccak256(abi.encodePacked(expectedMessage))) {
                emit log("Error: revert message not satisfied");
                fail();
            }
        }
    }

    /// @dev This is forge-only due to event checking
    function checkAuth(address _base, string memory _contractName) internal {
        AuthLike base = AuthLike(_base);
        uint256 ward = base.wards(address(this));

        // Ensure we have admin access
        GodMode.setWard(_base, address(this), 1);

        assertEq(base.wards(TEST_ADDRESS), 0);
        vm.expectEmit(true, false, false, true);
        emit Rely(TEST_ADDRESS);
        base.rely(TEST_ADDRESS);
        assertEq(base.wards(TEST_ADDRESS), 1);
        vm.expectEmit(true, false, false, true);
        emit Deny(TEST_ADDRESS);
        base.deny(TEST_ADDRESS);
        assertEq(base.wards(TEST_ADDRESS), 0);

        base.deny(address(this));

        vm.expectRevert(abi.encodePacked(_contractName, "/not-authorized"));
        base.rely(TEST_ADDRESS);
        vm.expectRevert(abi.encodePacked(_contractName, "/not-authorized"));
        base.deny(TEST_ADDRESS);

        // Reset admin access to what it was
        GodMode.setWard(_base, address(this), ward);
    }

    /// @dev This is forge-only due to event checking
    function checkFileUint(address _base, string memory _contractName, string[] memory _values) internal {
        FileLike base = FileLike(_base);
        uint256 ward = base.wards(address(this));

        // Ensure we have admin access
        GodMode.setWard(_base, address(this), 1);

        // First check an invalid value
        vm.expectRevert(abi.encodePacked(_contractName, "/file-unrecognized-param"));
        base.file("an invalid value", 1);

        // Next check each value is valid and updates the target storage slot
        for (uint256 i = 0; i < _values.length; i++) {
            string memory value = _values[i];
            bytes32 valueB32;
            assembly {
                valueB32 := mload(add(value, 32))
            }

            // Read original value
            (bool success, bytes memory result) = _base.call(abi.encodeWithSignature(string(abi.encodePacked(value, "()"))));
            assertTrue(success);
            uint256 origData = abi.decode(result, (uint256));
            uint256 newData;
            unchecked {
                newData = origData + 1;   // Overflow is fine
            }

            // Update value
            vm.expectEmit(true, false, false, true);
            emit File(valueB32, newData);
            base.file(valueB32, newData);

            // Confirm it was updated successfully
            (success, result) = _base.call(abi.encodeWithSignature(string(abi.encodePacked(value, "()"))));
            assertTrue(success);
            uint256 data = abi.decode(result, (uint256));
            assertEq(data, newData);

            // Reset value to original
            vm.expectEmit(true, false, false, true);
            emit File(valueB32, origData);
            base.file(valueB32, origData);
        }

        // Finally check that file is authed
        base.deny(address(this));
        vm.expectRevert(abi.encodePacked(_contractName, "/not-authorized"));
        base.file("some value", 1);

        // Reset admin access to what it was
        GodMode.setWard(_base, address(this), ward);
    }
    function checkFileUint(address _base, string memory _contractName, string[1] memory _values) internal {
        string[] memory values = new string[](1);
        values[0] = _values[0];
        checkFileUint(_base, _contractName, values);
    }
    function checkFileUint(address _base, string memory _contractName, string[2] memory _values) internal {
        string[] memory values = new string[](2);
        values[0] = _values[0];
        values[1] = _values[1];
        checkFileUint(_base, _contractName, values);
    }
    function checkFileUint(address _base, string memory _contractName, string[3] memory _values) internal {
        string[] memory values = new string[](3);
        values[0] = _values[0];
        values[1] = _values[1];
        values[2] = _values[2];
        checkFileUint(_base, _contractName, values);
    }
    function checkFileUint(address _base, string memory _contractName, string[4] memory _values) internal {
        string[] memory values = new string[](4);
        values[0] = _values[0];
        values[1] = _values[1];
        values[2] = _values[2];
        values[3] = _values[3];
        checkFileUint(_base, _contractName, values);
    }
    function checkFileUint(address _base, string memory _contractName, string[5] memory _values) internal {
        string[] memory values = new string[](5);
        values[0] = _values[0];
        values[1] = _values[1];
        values[2] = _values[2];
        values[3] = _values[3];
        values[4] = _values[4];
        checkFileUint(_base, _contractName, values);
    }
    function checkFileUint(address _base, string memory _contractName, string[6] memory _values) internal {
        string[] memory values = new string[](6);
        values[0] = _values[0];
        values[1] = _values[1];
        values[2] = _values[2];
        values[3] = _values[3];
        values[4] = _values[4];
        values[5] = _values[5];
        checkFileUint(_base, _contractName, values);
    }

    /// @dev This is forge-only due to event checking
    function checkFileAddress(address _base, string memory _contractName, string[] memory _values) internal {
        FileLike base = FileLike(_base);
        uint256 ward = base.wards(address(this));

        // Ensure we have admin access
        GodMode.setWard(_base, address(this), 1);

        // First check an invalid value
        vm.expectRevert(abi.encodePacked(_contractName, "/file-unrecognized-param"));
        base.file("an invalid value", TEST_ADDRESS);

        // Next check each value is valid and updates the target storage slot
        for (uint256 i = 0; i < _values.length; i++) {
            string memory value = _values[i];
            bytes32 valueB32;
            assembly {
                valueB32 := mload(add(value, 32))
            }

            // Read original value
            (bool success, bytes memory result) = _base.call(abi.encodeWithSignature(string(abi.encodePacked(value, "()"))));
            assertTrue(success);
            address origData = abi.decode(result, (address));
            address newData = TEST_ADDRESS;

            // Update value
            vm.expectEmit(true, false, false, true);
            emit File(valueB32, newData);
            base.file(valueB32, newData);

            // Confirm it was updated successfully
            (success, result) = _base.call(abi.encodeWithSignature(string(abi.encodePacked(value, "()"))));
            assertTrue(success);
            address data = abi.decode(result, (address));
            assertEq(data, newData);

            // Reset value to original
            vm.expectEmit(true, false, false, true);
            emit File(valueB32, origData);
            base.file(valueB32, origData);
        }

        // Finally check that file is authed
        base.deny(address(this));
        vm.expectRevert(abi.encodePacked(_contractName, "/not-authorized"));
        base.file("some value", TEST_ADDRESS);

        // Reset admin access to what it was
        GodMode.setWard(_base, address(this), ward);
    }
    function checkFileAddress(address _base, string memory _contractName, string[1] memory _values) internal {
        string[] memory values = new string[](1);
        values[0] = _values[0];
        checkFileAddress(_base, _contractName, values);
    }
    function checkFileAddress(address _base, string memory _contractName, string[2] memory _values) internal {
        string[] memory values = new string[](2);
        values[0] = _values[0];
        values[1] = _values[1];
        checkFileAddress(_base, _contractName, values);
    }
    function checkFileAddress(address _base, string memory _contractName, string[3] memory _values) internal {
        string[] memory values = new string[](3);
        values[0] = _values[0];
        values[1] = _values[1];
        values[2] = _values[2];
        checkFileAddress(_base, _contractName, values);
    }
    function checkFileAddress(address _base, string memory _contractName, string[4] memory _values) internal {
        string[] memory values = new string[](4);
        values[0] = _values[0];
        values[1] = _values[1];
        values[2] = _values[2];
        values[3] = _values[3];
        checkFileAddress(_base, _contractName, values);
    }
    function checkFileAddress(address _base, string memory _contractName, string[5] memory _values) internal {
        string[] memory values = new string[](5);
        values[0] = _values[0];
        values[1] = _values[1];
        values[2] = _values[2];
        values[3] = _values[3];
        values[4] = _values[4];
        checkFileAddress(_base, _contractName, values);
    }
    function checkFileAddress(address _base, string memory _contractName, string[6] memory _values) internal {
        string[] memory values = new string[](6);
        values[0] = _values[0];
        values[1] = _values[1];
        values[2] = _values[2];
        values[3] = _values[3];
        values[4] = _values[4];
        values[5] = _values[5];
        checkFileAddress(_base, _contractName, values);
    }

    /// @dev This is forge-only due to event checking
    function checkFileString(address _base, string memory _contractName, string[] memory _values) internal {
        FileLike base = FileLike(_base);
        uint256 ward = base.wards(address(this));

        // Ensure we have admin access
        GodMode.setWard(_base, address(this), 1);

        // First check an invalid value
        vm.expectRevert(abi.encodePacked(_contractName, "/file-unrecognized-param"));
        base.file("an invalid value", "");

        // Next check each value is valid and updates the target storage slot
        for (uint256 i = 0; i < _values.length; i++) {
            string memory value = _values[i];
            bytes32 valueB32;
            assembly {
                valueB32 := mload(add(value, 32))
            }

            // Read original value
            (bool success, bytes memory result) = _base.call(abi.encodeWithSignature(string(abi.encodePacked(value, "()"))));
            assertTrue(success);
            string memory origData = abi.decode(result, (string));
            string memory newData = string.concat(origData, " - NEW");

            // Update value
            vm.expectEmit(true, false, false, true);
            emit File(valueB32, newData);
            base.file(valueB32, newData);

            // Confirm it was updated successfully
            (success, result) = _base.call(abi.encodeWithSignature(string(abi.encodePacked(value, "()"))));
            assertTrue(success);
            string memory data = abi.decode(result, (string));
            assertEq(data, newData);

            // Reset value to original
            vm.expectEmit(true, false, false, true);
            emit File(valueB32, origData);
            base.file(valueB32, origData);
        }

        // Finally check that file is authed
        base.deny(address(this));
        vm.expectRevert(abi.encodePacked(_contractName, "/not-authorized"));
        base.file("some value", "");

        // Reset admin access to what it was
        GodMode.setWard(_base, address(this), ward);
    }
    function checkFileString(address _base, string memory _contractName, string[1] memory _values) internal {
        string[] memory values = new string[](1);
        values[0] = _values[0];
        checkFileString(_base, _contractName, values);
    }
    function checkFileString(address _base, string memory _contractName, string[2] memory _values) internal {
        string[] memory values = new string[](2);
        values[0] = _values[0];
        values[1] = _values[1];
        checkFileString(_base, _contractName, values);
    }
    function checkFileString(address _base, string memory _contractName, string[3] memory _values) internal {
        string[] memory values = new string[](3);
        values[0] = _values[0];
        values[1] = _values[1];
        values[2] = _values[2];
        checkFileString(_base, _contractName, values);
    }
    function checkFileString(address _base, string memory _contractName, string[4] memory _values) internal {
        string[] memory values = new string[](4);
        values[0] = _values[0];
        values[1] = _values[1];
        values[2] = _values[2];
        values[3] = _values[3];
        checkFileString(_base, _contractName, values);
    }
    function checkFileString(address _base, string memory _contractName, string[5] memory _values) internal {
        string[] memory values = new string[](5);
        values[0] = _values[0];
        values[1] = _values[1];
        values[2] = _values[2];
        values[3] = _values[3];
        values[4] = _values[4];
        checkFileString(_base, _contractName, values);
    }
    function checkFileString(address _base, string memory _contractName, string[6] memory _values) internal {
        string[] memory values = new string[](6);
        values[0] = _values[0];
        values[1] = _values[1];
        values[2] = _values[2];
        values[3] = _values[3];
        values[4] = _values[4];
        values[5] = _values[5];
        checkFileString(_base, _contractName, values);
    }

    function checkModifier(address _base, string memory _revertMsg, bytes4[] memory _fsigs) internal {
        for (uint256 i = 0; i < _fsigs.length; i++) {
            bytes4 fsig = _fsigs[i];
            uint256 p = 0;
            // Pad the abi call with 0s to fill all the args (it's okay to supply more than the function requires)
            assertRevert(_base, abi.encodePacked(fsig, p, p, p, p, p, p), _revertMsg);
        }
    }
    function checkModifier(address _base, string memory _revertMsg, bytes4[1] memory _fsigs) internal {
        bytes4[] memory fsigs = new bytes4[](1);
        fsigs[0] = _fsigs[0];
        checkModifier(_base, _revertMsg, fsigs);
    }
    function checkModifier(address _base, string memory _revertMsg, bytes4[2] memory _fsigs) internal {
        bytes4[] memory fsigs = new bytes4[](2);
        fsigs[0] = _fsigs[0];
        fsigs[1] = _fsigs[1];
        checkModifier(_base, _revertMsg, fsigs);
    }
    function checkModifier(address _base, string memory _revertMsg, bytes4[3] memory _fsigs) internal {
        bytes4[] memory fsigs = new bytes4[](3);
        fsigs[0] = _fsigs[0];
        fsigs[1] = _fsigs[1];
        fsigs[2] = _fsigs[2];
        checkModifier(_base, _revertMsg, fsigs);
    }
    function checkModifier(address _base, string memory _revertMsg, bytes4[4] memory _fsigs) internal {
        bytes4[] memory fsigs = new bytes4[](4);
        fsigs[0] = _fsigs[0];
        fsigs[1] = _fsigs[1];
        fsigs[2] = _fsigs[2];
        fsigs[3] = _fsigs[3];
        checkModifier(_base, _revertMsg, fsigs);
    }
    function checkModifier(address _base, string memory _revertMsg, bytes4[5] memory _fsigs) internal {
        bytes4[] memory fsigs = new bytes4[](5);
        fsigs[0] = _fsigs[0];
        fsigs[1] = _fsigs[1];
        fsigs[2] = _fsigs[2];
        fsigs[3] = _fsigs[3];
        fsigs[4] = _fsigs[4];
        checkModifier(_base, _revertMsg, fsigs);
    }
    function checkModifier(address _base, string memory _revertMsg, bytes4[6] memory _fsigs) internal {
        bytes4[] memory fsigs = new bytes4[](6);
        fsigs[0] = _fsigs[0];
        fsigs[1] = _fsigs[1];
        fsigs[2] = _fsigs[2];
        fsigs[3] = _fsigs[3];
        fsigs[4] = _fsigs[4];
        fsigs[5] = _fsigs[5];
        checkModifier(_base, _revertMsg, fsigs);
    }
    function checkModifier(address _base, string memory _revertMsg, bytes4[7] memory _fsigs) internal {
        bytes4[] memory fsigs = new bytes4[](7);
        fsigs[0] = _fsigs[0];
        fsigs[1] = _fsigs[1];
        fsigs[2] = _fsigs[2];
        fsigs[3] = _fsigs[3];
        fsigs[4] = _fsigs[4];
        fsigs[5] = _fsigs[5];
        fsigs[6] = _fsigs[6];
        checkModifier(_base, _revertMsg, fsigs);
    }
    function checkModifier(address _base, string memory _revertMsg, bytes4[8] memory _fsigs) internal {
        bytes4[] memory fsigs = new bytes4[](8);
        fsigs[0] = _fsigs[0];
        fsigs[1] = _fsigs[1];
        fsigs[2] = _fsigs[2];
        fsigs[3] = _fsigs[3];
        fsigs[4] = _fsigs[4];
        fsigs[5] = _fsigs[5];
        fsigs[6] = _fsigs[6];
        fsigs[7] = _fsigs[7];
        checkModifier(_base, _revertMsg, fsigs);
    }
    function checkModifier(address _base, string memory _revertMsg, bytes4[9] memory _fsigs) internal {
        bytes4[] memory fsigs = new bytes4[](9);
        fsigs[0] = _fsigs[0];
        fsigs[1] = _fsigs[1];
        fsigs[2] = _fsigs[2];
        fsigs[3] = _fsigs[3];
        fsigs[4] = _fsigs[4];
        fsigs[5] = _fsigs[5];
        fsigs[6] = _fsigs[6];
        fsigs[7] = _fsigs[7];
        fsigs[8] = _fsigs[8];
        checkModifier(_base, _revertMsg, fsigs);
    }
    function checkModifier(address _base, string memory _revertMsg, bytes4[10] memory _fsigs) internal {
        bytes4[] memory fsigs = new bytes4[](10);
        fsigs[0] = _fsigs[0];
        fsigs[1] = _fsigs[1];
        fsigs[2] = _fsigs[2];
        fsigs[3] = _fsigs[3];
        fsigs[4] = _fsigs[4];
        fsigs[5] = _fsigs[5];
        fsigs[6] = _fsigs[6];
        fsigs[7] = _fsigs[7];
        fsigs[8] = _fsigs[8];
        fsigs[9] = _fsigs[9];
        checkModifier(_base, _revertMsg, fsigs);
    }

}
