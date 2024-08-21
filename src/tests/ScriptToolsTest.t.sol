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

    string loadedExports;

    function test_stringToBytes32() public pure {
        assertEq(ScriptTools.stringToBytes32("test"),  bytes32("test"));
    }

    function test_stringToBytes32_empty() public pure {
        assertEq(ScriptTools.stringToBytes32(""),  bytes32(""));
    }

    function test_ilkToChainlogFormat() public pure {
        assertEq(ScriptTools.ilkToChainlogFormat(bytes32("ETH-A")), "ETH_A");
    }

    function test_ilkToChainlogFormat_empty() public pure {
        assertEq(ScriptTools.ilkToChainlogFormat(bytes32("")), "");
    }

    function test_ilkToChainlogFormat_multiple() public pure {
        assertEq(ScriptTools.ilkToChainlogFormat(bytes32("DIRECT-AAVEV2-DAI")), "DIRECT_AAVEV2_DAI");
    }

    function test_eq() public pure {
        assertTrue(ScriptTools.eq("A", "A"));
    }

    function test_not_eq() public pure {
        assertTrue(!ScriptTools.eq("A", "B"));
    }

    function test_export() public {
        // Export some contracts and write to output
        ScriptTools.exportContract("myExports", "addr1", address(0x1));
        ScriptTools.exportContract("myExports", "addr2", address(0x2));
        address[] memory addr34 = new address[](2);
        addr34[0] = address(0x3);
        addr34[1] = address(0x4);
        ScriptTools.exportContracts("myExports", "addr34", addr34);

        // Simulate a subsequent run loading a previously written file (use latest deploy)
        loadedExports = ScriptTools.readOutput("myExports", 1);
        assertEq(stdJson.readAddress(loadedExports, ".addr1"), address(0x1));
        assertEq(stdJson.readAddress(loadedExports, ".addr2"), address(0x2));
        assertEq(stdJson.readAddressArray(loadedExports, ".addr34"), addr34);

        // Export some values and write to output
        ScriptTools.exportValue("myExports", "label1", 1);
        ScriptTools.exportValue("myExports", "label2", 2);

        // Simulate a subsequent run loading a previously written file (use latest deploy)
        loadedExports = ScriptTools.readOutput("myExports", 1);
        assertEq(stdJson.readUint(loadedExports, ".label1"), 1);
        assertEq(stdJson.readUint(loadedExports, ".label2"), 2);

        // Export some values and write to output
        ScriptTools.exportValue("myExports", "str-label1", "str1");
        ScriptTools.exportValue("myExports", "str-label2", "str2");

        // Simulate a subsequent run loading a previously written file (use latest deploy)
        loadedExports = ScriptTools.readOutput("myExports", 1);
        assertEq(stdJson.readString(loadedExports, ".str-label1"), "str1");
        assertEq(stdJson.readString(loadedExports, ".str-label2"), "str2");
    }

}
