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

import "forge-std/Test.sol";

import {GodMode} from "./GodMode.sol";
import {MCD,MCDMainnet,MCDGoerli} from "./MCD.sol";
import {MCDUser} from "./MCDUser.sol";

interface AuthLike {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
}

interface FileLike is AuthLike {
    function file(bytes32, uint256) external;
    function file(bytes32, address) external;
}

abstract contract DSSTest is Test {

    uint256 constant WAD = 10 ** 18;
    uint256 constant RAY = 10 ** 27;
    uint256 constant RAD = 10 ** 45;
    uint256 constant BPS = 10 ** 4;

    uint256 constant THOUSAND = 10 ** 3;
    uint256 constant MILLION = 10 ** 6;
    uint256 constant BILLION = 10 ** 9;

    address constant TEST_ADDRESS = address(bytes20(uint160(uint256(keccak256('random test address')))));

    MCD mcd;

    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event File(bytes32 indexed what, uint256 data);
    event File(bytes32 indexed what, address data);

    function setUp() public virtual {
        mcd = setupEnv();

        postSetup();
    }

    function autoDetectEnv() internal returns (MCD) {
        // Auto-detect using chainid
        uint256 id;
        assembly {
            id := chainid()
        }
        if (id == 1) {
            // Ethereum Mainnet
            return new MCDMainnet();
        } else if (id == 5) {
            // Goerli Testnet
            return new MCDGoerli();
        } else {
            return new MCD();
        }
    }

    function setupEnv() internal virtual returns (MCD) {
        return new MCD();
    }

    function postSetup() internal virtual {
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

}
