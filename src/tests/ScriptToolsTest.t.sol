// SPDX-License-Identifier: AGPL-3.0-or-later
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

import "../DssTest.sol";
import "../ScriptTools.sol";

contract ScriptToolTest is DssTest {

    function test_stringToBytes32() public {
        assertEq(ScriptTools.stringToBytes32("test"),  bytes32("test"));
    }

    function test_stringToBytes32_empty() public {
        assertEq(ScriptTools.stringToBytes32(""),  bytes32(""));
    }

    function test_ilkToChainlogFormat() public {
        assertEq(ScriptTools.ilkToChainlogFormat(bytes32("ETH-A")), "ETH_A");
    }

    function test_ilkToChainlogFormat_empty() public {
        assertEq(ScriptTools.ilkToChainlogFormat(bytes32("")), "");
    }

    function test_ilkToChainlogFormat_multiple() public {
        assertEq(ScriptTools.ilkToChainlogFormat(bytes32("DIRECT-AAVEV2-DAI")), "DIRECT_AAVEV2_DAI");
    }

    function test_eq() public {
        assertTrue(ScriptTools.eq("A", "A"));
    }

    function test_not_eq() public {
        assertTrue(!ScriptTools.eq("A", "B"));
    }

}
