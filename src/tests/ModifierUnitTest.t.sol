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

import "../DssTest.sol";

contract SomeContract {
    modifier myModifier { if (1 != 0) revert("SomeContract/bad-state"); _; }    // Conditional gets rid of code unreachable warning
    function withModifier(uint256 arg) external myModifier {}
    function withoutModifier(uint256 arg) external {}
}

contract ModifierUnitTest is DssTest {

    function test_modifier() public {
        checkModifier(address(new SomeContract()), "SomeContract/bad-state", [SomeContract.withModifier.selector]);
    }
    function testFail_modifier_not_present() public {
        checkModifier(address(new SomeContract()), "SomeContract/bad-state", [SomeContract.withoutModifier.selector]);
    }

}
