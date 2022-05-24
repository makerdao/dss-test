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

import "../DSSTest.sol";

abstract contract IntegrationTest is DSSTest {

    using GodMode for *;

    MCDUser user1;
    MCDUser user2;
    MCDUser user3;

    function setupEnv() internal virtual override returns (MCD) {
        return autoDetectEnv();
    }

    function postSetup() internal virtual override {
        user1 = mcd.newUser();
        user2 = mcd.newUser();
        user3 = mcd.newUser();
    }

    function test_give_tokens() public {
        mcd.dai().setBalance(address(this), 100 ether);
        assertEq(mcd.dai().balanceOf(address(this)), 100 ether);
    }

    function test_create_liquidation() public {
        uint256 prevKicks = mcd.wethAClip().kicks();
        user1.createAuction(mcd.wethAJoin(), 100 ether);
        assertEq(mcd.wethAClip().kicks(), prevKicks + 1);
    }

    function test_auth() public {
        // Test that the vesting contract has proper auth setup
        // Note: can only test against newer style contracts that don't use LibNote
        checkAuth(mcd.chainlog().getAddress("MCD_VEST_DAI"), "DssVest");
    }

    function test_file_uint() public {
        // Test that the end contract has proper file
        // Note: can only test against newer style contracts that don't use LibNote
        checkFileUint(mcd.chainlog().getAddress("MCD_END"), "End", ["wait"]);
    }

    function test_file_address() public {
        // Test that the end contract has proper file
        // Note: can only test against newer style contracts that don't use LibNote
        checkFileAddress(mcd.chainlog().getAddress("MCD_END"), "End", ["vat", "cat", "dog", "vow", "pot", "spot"]);
    }

}
