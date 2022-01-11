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

import "dss-interfaces/Interfaces.sol";

import {MCDUser} from "./MCDUser.sol";

/// @dev An instance of MCD with all relevant references
contract MCD {

    // Core MCD
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

    constructor() public {
        vat = VatAbstract(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
        daiJoin = DaiJoinAbstract(0x9759A6Ac90977b93B58547b4A71c78317f391A28);
        dai = DaiAbstract(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        vow = VowAbstract(0xA950524441892A31ebddF91d3cEEFa04Bf454466);
        dog = DogAbstract(0x135954d155898D42C90D2a57824C690e0c7BEf1B);
        pot = PotAbstract(0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7);
        jug = JugAbstract(0x19c0976f590D67707E62397C87829d896Dc0f1F1);
        spotter = SpotAbstract(0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3);
        weth = DSTokenAbstract(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        wethPip = OsmAbstract(0x81FE72B5A8d1A857d176C3E7d5Bd2679A9B85763);
        wethAJoin = GemJoinAbstract(0x2F0b23f53734252Bda2277357e97e1517d6B042A);
        wethAClip = ClipAbstract(0xc67963a226eddd77B91aD8c421630A1b0AdFF270);
        wbtc = DSTokenAbstract(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
        wbtcPip = OsmAbstract(0xf185d0682d50819263941e5f4EacC763CC5C6C42);
        wbtcAJoin = GemJoinAbstract(0xBF72Da2Bd84c5170618Fbe5914B0ECA9638d5eb5);
        wbtcAClip = ClipAbstract(0x0227b54AdbFAEec5f1eD1dFa11f54dcff9076e2C);
    }

}

contract MCDGoerli is MCD {

    constructor() public {
        vat = VatAbstract(0xB966002DDAa2Baf48369f5015329750019736031);
        daiJoin = DaiJoinAbstract(0x6a60b7070befb2bfc964F646efDF70388320f4E0);
        dai = DaiAbstract(0x11fE4B6AE13d2a6055C8D9cF65c55bac32B5d844);
        vow = VowAbstract(0x23f78612769b9013b3145E43896Fa1578cAa2c2a);
        dog = DogAbstract(0x5cf85A37Dbd28A239698B4F9aA9a03D55C04F292);
        pot = PotAbstract(0x50672F0a14B40051B65958818a7AcA3D54Bd81Af);
        jug = JugAbstract(0xC90C99FE9B5d5207A03b9F28A6E8A19C0e558916);
        spotter = SpotAbstract(0xACe2A9106ec175bd56ec05C9E38FE1FDa8a1d758);
        weth = DSTokenAbstract(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6);
        wethPip = OsmAbstract(0x94588e35fF4d2E99ffb8D5095F35d1E37d6dDf12);
        wethAJoin = GemJoinAbstract(0x2372031bB0fC735722AA4009AeBf66E8BEAF4BA1);
        wethAClip = ClipAbstract(0x2603c6EC5878dC70f53aD3a90e4330ba536d2385);
        wbtc = DSTokenAbstract(0x7ccF0411c7932B99FC3704d68575250F032e3bB7);
        wbtcPip = OsmAbstract(0xE7de200a3a29E9049E378b52BD36701A0Ce68C3b);
        wbtcAJoin = GemJoinAbstract(0x3cbE712a12e651eEAF430472c0C1BF1a2a18939D);
        wbtcAClip = ClipAbstract(0x752c35fa3d21863257bbBCB7e2B344fd0948B61b);
    }

}
