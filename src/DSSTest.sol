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

import "ds-test/test.sol";

import {GodMode} from "./GodMode.sol";
import {MCD,MCDMainnet,MCDGoerli} from "./MCD.sol";
import {MCDUser} from "./MCDUser.sol";

interface AuthLike {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
}

abstract contract DSSTest is DSTest {

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

    function _tryFile(address base, bytes32 what, address data) private returns (bool ok) {
        (ok,) = base.call(abi.encodeWithSignature("file(bytes32,address)", what, data));
    }
    function _tryFile(address base, bytes32 what, uint256 data) private returns (bool ok) {
        (ok,) = base.call(abi.encodeWithSignature("file(bytes32,address,uint256)", what, data));
    }
    function _tryFile(address base, bytes32 ilk, bytes32 what, address data) private returns (bool ok) {
        (ok,) = base.call(abi.encodeWithSignature("file(bytes32,bytes32,address)", ilk, what, data));
    }
    function _tryFile(address base, bytes32 ilk, bytes32 what, uint256 data) private returns (bool ok) {
        (ok,) = base.call(abi.encodeWithSignature("file(bytes32,bytes32,uint256)", ilk, what, data));
    }

    /// @dev This is forge-only due to event checking
    function checkAuth(address _base, string contractName) internal {
        AuthLike base = AuthLike(_base);
        uint256 ward = base.wards(address(this));

        // Ensure we have admin access
        GodMode.setWard(address(this), 1);

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

        assertTrue(!_tryRely(TEST_ADDRESS));
        assertTrue(!_tryDeny(TEST_ADDRESS));

        // Reset admin access to what it was
        GodMode.setWard(address(this), 1);
    }

}
