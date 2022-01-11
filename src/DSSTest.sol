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
pragma solidity >=0.6.12;

import "ds-test/test.sol";

import {GodMode} from "./GodMode.sol";
import {MCD,MCDMainnet,MCDGoerli} from "./MCD.sol";
import {MCDUser} from "./MCDUser.sol";

abstract contract DSSTest is DSTest {

    uint256 constant WAD = 10 ** 18;
    uint256 constant RAY = 10 ** 27;
    uint256 constant RAD = 10 ** 45;
    uint256 constant BPS = 10 ** 4;

    uint256 constant THOUSAND = 10 ** 3;
    uint256 constant MILLION = 10 ** 6;
    uint256 constant BILLION = 10 ** 9;

    MCD mcd;

    function setUp() public virtual {
        postSetup();
    }

    function postSetup() internal virtual;

}
