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

import "dss-interfaces/Interfaces.sol";

import {MCDUser} from "./MCDUser.sol";

/// @dev An instance of MCD with all relevant references
contract MCD {

    // Core MCD
    ChainlogAbstract public chainlog;
    VatAbstract public vat;
    DaiJoinAbstract public daiJoin;
    DaiAbstract public dai;
    VowAbstract public vow;
    DogAbstract public dog;
    PotAbstract public pot;
    JugAbstract public jug;
    SpotAbstract public spotter;

    // ETH-A
    DSTokenAbstract public weth;
    OsmAbstract public wethPip;
    GemJoinAbstract public wethAJoin;
    ClipAbstract public wethAClip;

    // WBTC-A
    DSTokenAbstract public wbtc;
    OsmAbstract public wbtcPip;
    GemJoinAbstract public wbtcAJoin;
    ClipAbstract public wbtcAClip;

    function loadFromChainlog(ChainlogAbstract _chainlog) public {
        chainlog = _chainlog;
        vat = VatAbstract(chainlog.getAddress("MCD_VAT"));
        daiJoin = DaiJoinAbstract(chainlog.getAddress("MCD_JOIN_DAI"));
        dai = DaiAbstract(chainlog.getAddress("MCD_DAI"));
        vow = VowAbstract(chainlog.getAddress("MCD_VOW"));
        dog = DogAbstract(chainlog.getAddress("MCD_DOG"));
        pot = PotAbstract(chainlog.getAddress("MCD_POT"));
        jug = JugAbstract(chainlog.getAddress("MCD_JUG"));
        spotter = SpotAbstract(chainlog.getAddress("MCD_SPOT"));
        weth = DSTokenAbstract(chainlog.getAddress("ETH"));
        wethPip = OsmAbstract(chainlog.getAddress("PIP_ETH"));
        wethAJoin = GemJoinAbstract(chainlog.getAddress("MCD_JOIN_ETH_A"));
        wethAClip = ClipAbstract(chainlog.getAddress("MCD_CLIP_ETH_A"));
        wbtc = DSTokenAbstract(chainlog.getAddress("WBTC"));
        wbtcPip = OsmAbstract(chainlog.getAddress("PIP_WBTC"));
        wbtcAJoin = GemJoinAbstract(chainlog.getAddress("MCD_JOIN_WBTC_A"));
        wbtcAClip = ClipAbstract(chainlog.getAddress("MCD_CLIP_WBTC_A"));
    }

    function newUser() public returns (MCDUser) {
        return new MCDUser(this);
    }

    /// @dev Deploy a fresh new ilk
    function deployIlk(
        GemJoinAbstract join
    ) public {

    }

}

contract MCDMainnet is MCD {

    constructor() {
        loadFromChainlog(ChainlogAbstract(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F));
    }

}

contract MCDGoerli is MCD {

    constructor() {
        loadFromChainlog(ChainlogAbstract(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F));
    }

}
