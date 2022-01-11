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
pragma solidity 0.6.12;

import "../DSSTest.sol";

contract MainnetTest is DSSTest {

    function postSetup() internal virtual override {
        mcd = new MCDMainnet();
    }

    function test_sanity() public {
        assertEq(address(mcd.vat()), 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
    }

}
