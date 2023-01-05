// SPDX-FileCopyrightText: © 2022 Dai Foundation <www.daifoundation.org>
// SPDX-License-Identifier: AGPL-3.0-or-later
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
import {GodMode} from "./GodMode.sol";

contract DSValue {
    bool    has;
    bytes32 val;
    function peek() public view returns (bytes32, bool) {
        return (val,has);
    }
    function read() external view returns (bytes32) {
        bytes32 wut; bool haz;
        (wut, haz) = peek();
        require(haz, "haz-not");
        return wut;
    }
    function poke(bytes32 wut) external {
        val = wut;
        has = true;
    }
    function void() external {
        val = bytes32(0);
        has = false;
    }
}

struct DssInstance {
    ChainlogAbstract chainlog;
    VatAbstract vat;
    DaiJoinAbstract daiJoin;
    DaiAbstract dai;
    VowAbstract vow;
    DogAbstract dog;
    PotAbstract pot;
    JugAbstract jug;
    SpotAbstract spotter;
    EndAbstract end;
    CureAbstract cure;
    FlapAbstract flap;
    FlopAbstract flop;
    ESMAbstract esm;
}

struct DssIlkInstance {
    DSTokenAbstract gem;
    OsmAbstract pip;
    GemJoinAbstract join;
    ClipAbstract clip;
}

library MCD {

    uint256 constant WAD = 10 ** 18;
    uint256 constant RAY = 10 ** 27;
    uint256 constant RAD = 10 ** 45;

    function getAddressOrNull(DssInstance memory dss, bytes32 key) internal view returns (address) {
        try dss.chainlog.getAddress(key) returns (address a) {
            return a;
        } catch {
            return address(0);
        }
    }

    function loadFromChainlog(address chainlog) internal view returns (DssInstance memory dss) {
        return loadFromChainlog(ChainlogAbstract(chainlog));
    }

    function loadFromChainlog(ChainlogAbstract chainlog) internal view returns (DssInstance memory dss) {
        dss.chainlog = chainlog;
        dss.vat = VatAbstract(getAddressOrNull(dss, "MCD_VAT"));
        dss.daiJoin = DaiJoinAbstract(getAddressOrNull(dss, "MCD_JOIN_DAI"));
        dss.dai = DaiAbstract(getAddressOrNull(dss, "MCD_DAI"));
        dss.vow = VowAbstract(getAddressOrNull(dss, "MCD_VOW"));
        dss.dog = DogAbstract(getAddressOrNull(dss, "MCD_DOG"));
        dss.pot = PotAbstract(getAddressOrNull(dss, "MCD_POT"));
        dss.jug = JugAbstract(getAddressOrNull(dss, "MCD_JUG"));
        dss.spotter = SpotAbstract(getAddressOrNull(dss, "MCD_SPOT"));
        dss.end = EndAbstract(getAddressOrNull(dss, "MCD_END"));
        dss.cure = CureAbstract(getAddressOrNull(dss, "MCD_CURE"));
        dss.flap = FlapAbstract(getAddressOrNull(dss, "MCD_FLAP"));
        dss.flop = FlopAbstract(getAddressOrNull(dss, "MCD_FLOP"));
        dss.esm = ESMAbstract(getAddressOrNull(dss, "MCD_ESM"));
    }

    function bytesToBytes32(bytes memory b) private pure returns (bytes32) {
        bytes32 out;
        for (uint256 i = 0; i < b.length; i++) {
            out |= bytes32(b[i] & 0xFF) >> (i * 8);
        }
        return out;
    }

    function getIlk(DssInstance memory dss, string memory gem, string memory variant) internal view returns (DssIlkInstance memory) {
        return DssIlkInstance(
            DSTokenAbstract(getAddressOrNull(dss, bytesToBytes32(bytes(gem)))),
            OsmAbstract(getAddressOrNull(dss, bytesToBytes32(abi.encodePacked("PIP_", gem)))),
            GemJoinAbstract(getAddressOrNull(dss, bytesToBytes32(abi.encodePacked("MCD_JOIN_", gem, "_", variant)))),
            ClipAbstract(getAddressOrNull(dss, bytesToBytes32(abi.encodePacked("MCD_CLIP_", gem, "_", variant))))
        );
    }

    /// @dev Initialize a dummy ilk with a $1 DSValue pip without liquidations
    function initIlk(
        DssInstance memory dss,
        bytes32 ilk
    ) internal {
        DSValue pip = new DSValue();
        pip.poke(bytes32(WAD));
        initIlk(dss, ilk, address(0), address(pip));
    }

    /// @dev Initialize an ilk with a $1 DSValue pip without liquidations
    function initIlk(
        DssInstance memory dss,
        bytes32 ilk,
        address join
    ) internal {
        DSValue pip = new DSValue();
        pip.poke(bytes32(WAD));
        initIlk(dss, ilk, join, address(pip));
    }

    /// @dev Initialize an ilk without liquidations
    function initIlk(
        DssInstance memory dss,
        bytes32 ilk,
        address join,
        address pip
    ) internal {
        dss.vat.init(ilk);
        dss.jug.init(ilk);

        dss.vat.rely(join);

        dss.spotter.file(ilk, "pip", pip);
        dss.spotter.file(ilk, "mat", RAY);
        dss.spotter.poke(ilk);
    }

    /// @dev Initialize an ilk with liquidations
    function initIlk(
        DssInstance memory dss,
        bytes32 ilk,
        address join,
        address pip,
        address clip,
        address clipCalc
    ) internal {
        initIlk(dss, ilk, join, pip);

        // TODO liquidations
        clip; clipCalc;
    }

    /// @dev Give who a ward on all core contracts
    function giveAdminAccess(DssInstance memory dss, address who) internal {
        if (address(dss.vat) != address(0)) GodMode.setWard(address(dss.vat), who, 1);
        if (address(dss.dai) != address(0)) GodMode.setWard(address(dss.dai), who, 1);
        if (address(dss.vow) != address(0)) GodMode.setWard(address(dss.vow), who, 1);
        if (address(dss.dog) != address(0)) GodMode.setWard(address(dss.dog), who, 1);
        if (address(dss.pot) != address(0)) GodMode.setWard(address(dss.pot), who, 1);
        if (address(dss.jug) != address(0)) GodMode.setWard(address(dss.jug), who, 1);
        if (address(dss.spotter) != address(0)) GodMode.setWard(address(dss.spotter), who, 1);
        if (address(dss.end) != address(0)) GodMode.setWard(address(dss.end), who, 1);
        if (address(dss.cure) != address(0)) GodMode.setWard(address(dss.cure), who, 1);
        if (address(dss.esm) != address(0)) GodMode.setWard(address(dss.esm), who, 1);
    }

    /// @dev Give who a ward on all core contracts to this address
    function giveAdminAccess(DssInstance memory dss) internal {
        giveAdminAccess(dss, address(this));
    }

    function newUser(DssInstance memory dss) internal returns (MCDUser) {
        return new MCDUser(dss);
    }

}
