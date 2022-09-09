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

struct Ilk {
    DSTokenAbstract gem;
    OsmAbstract pip;
    GemJoinAbstract join;
    ClipAbstract clip;
}

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
    EndAbstract public end;
    CureAbstract public cure;
    FlapAbstract public flap;
    FlopAbstract public flop;

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

    function getAddressOrNull(bytes32 key) public view returns (address) {
        try chainlog.getAddress(key) returns (address a) {
            return a;
        } catch {
            return address(0);
        }
    }

    function loadFromChainlog(ChainlogAbstract _chainlog) public {
        chainlog = _chainlog;
        vat = VatAbstract(getAddressOrNull("MCD_VAT"));
        daiJoin = DaiJoinAbstract(getAddressOrNull("MCD_JOIN_DAI"));
        dai = DaiAbstract(getAddressOrNull("MCD_DAI"));
        vow = VowAbstract(getAddressOrNull("MCD_VOW"));
        dog = DogAbstract(getAddressOrNull("MCD_DOG"));
        pot = PotAbstract(getAddressOrNull("MCD_POT"));
        jug = JugAbstract(getAddressOrNull("MCD_JUG"));
        spotter = SpotAbstract(getAddressOrNull("MCD_SPOT"));
        end = EndAbstract(getAddressOrNull("MCD_END"));
        cure = CureAbstract(getAddressOrNull("MCD_CURE"));
        flap = FlapAbstract(getAddressOrNull("MCD_FLAP"));
        flop = FlopAbstract(getAddressOrNull("MCD_FLOP"));

        weth = DSTokenAbstract(getAddressOrNull("ETH"));
        wethPip = OsmAbstract(getAddressOrNull("PIP_ETH"));
        wethAJoin = GemJoinAbstract(getAddressOrNull("MCD_JOIN_ETH_A"));
        wethAClip = ClipAbstract(getAddressOrNull("MCD_CLIP_ETH_A"));

        wbtc = DSTokenAbstract(getAddressOrNull("WBTC"));
        wbtcPip = OsmAbstract(getAddressOrNull("PIP_WBTC"));
        wbtcAJoin = GemJoinAbstract(getAddressOrNull("MCD_JOIN_WBTC_A"));
        wbtcAClip = ClipAbstract(getAddressOrNull("MCD_CLIP_WBTC_A"));
    }

    function bytesToBytes32(bytes memory b) private pure returns (bytes32) {
        bytes32 out;
        for (uint256 i = 0; i < b.length; i++) {
            out |= bytes32(b[i] & 0xFF) >> (i * 8);
        }
        return out;
    }

    function getIlk(string memory gem, string memory variant) public view returns (Ilk memory) {
        return Ilk(
            DSTokenAbstract(getAddressOrNull(bytesToBytes32(bytes(gem)))),
            OsmAbstract(getAddressOrNull(bytesToBytes32(abi.encodePacked("PIP_", gem)))),
            GemJoinAbstract(getAddressOrNull(bytesToBytes32(abi.encodePacked("MCD_JOIN_", gem, "_", variant)))),
            ClipAbstract(getAddressOrNull(bytesToBytes32(abi.encodePacked("MCD_CLIP_", gem, "_", variant))))
        );
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
