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
import {GodMode} from "./GodMode.sol";

// TODO remove this when available in dss-interfaces
interface CureAbstract {
    function wards(address) external view returns (uint256);
    function live() external view returns (uint256);
    function srcs(uint256) external view returns (address);
    function wait() external view returns (uint256);
    function when() external view returns (uint256);
    function pos(address) external view returns (uint256);
    function amt(address) external view returns (uint256);
    function loadded(address) external view returns (uint256);
    function lCount() external view returns (uint256);
    function say() external view returns (uint256);
    function tCount() external view returns (uint256);
    function list() external view returns (address[] memory);
    function tell() external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function file(bytes32, uint256) external;
    function lift(address) external;
    function drop(address) external;
    function cage() external;
    function load(address) external;
}

/// @dev An instance of MCD with all relevant references
contract MCD {

    ChainlogAbstract public chainlog;

    // Core MCD
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

    function loadCore(
        address _vat,
        address _daiJoin,
        address _dai,
        address _vow,
        address _dog,
        address _pot,
        address _jug,
        address _spotter,
        address _end,
        address _cure
    ) public {
        vat = VatAbstract(_vat);
        daiJoin = DaiJoinAbstract(_daiJoin);
        dai = DaiAbstract(_dai);
        vow = VowAbstract(_vow);
        dog = DogAbstract(_dog);
        pot = PotAbstract(_pot);
        jug = JugAbstract(_jug);
        spotter = SpotAbstract(_spotter);
        end = EndAbstract(_end);
        cure = CureAbstract(_cure);
    }

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
        end = EndAbstract(chainlog.getAddress("MCD_END"));
        cure = CureAbstract(chainlog.getAddress("MCD_CURE"));

        weth = DSTokenAbstract(chainlog.getAddress("ETH"));
        wethPip = OsmAbstract(chainlog.getAddress("PIP_ETH"));
        wethAJoin = GemJoinAbstract(chainlog.getAddress("MCD_JOIN_ETH_A"));
        wethAClip = ClipAbstract(chainlog.getAddress("MCD_CLIP_ETH_A"));

        wbtc = DSTokenAbstract(chainlog.getAddress("WBTC"));
        wbtcPip = OsmAbstract(chainlog.getAddress("PIP_WBTC"));
        wbtcAJoin = GemJoinAbstract(chainlog.getAddress("MCD_JOIN_WBTC_A"));
        wbtcAClip = ClipAbstract(chainlog.getAddress("MCD_CLIP_WBTC_A"));
    }

    /// @dev Initialize the core of MCD
    function init() public {
        require(vat != address(0), "vat not set");
        require(daiJoin != address(0), "daiJoin not set");
        require(dai != address(0), "dai not set");
        require(vow != address(0), "vow not set");
        require(dog != address(0), "dog not set");
        require(pot != address(0), "pot not set");
        require(jug != address(0), "jug not set");
        require(spotter != address(0), "spotter not set");
        require(end != address(0), "end not set");
        require(cure != address(0), "cure not set");

        vat.rely(address(jug));
        vat.rely(address(dog));
        vat.rely(address(pot));
        vat.rely(address(jug));
        vat.rely(address(spotter));
        vat.rely(address(end));

        dai.rely(address(daiJoin));

        dog.file("vow", address(vow));

        pot.rely(address(end));

        spotter.rely(address(end));

        end.file("vat", address(vat));
        end.file("pot", address(pot));
        end.file("spot", address(spotter));
        end.file("cure", address(cure));
        end.file("vow", address(vow));

        cure.rely(address(end));
    }

    /// @dev Initialize an ilk with a $1 DSValue pip without liquidations
    function initIlk(
        bytes32 ilk,
        address join
    ) public {
        DSValue pip = new DSValue();
        pip.poke(bytes32(10 ** 18));
        initIlk(join, address(pip));
    }

    /// @dev Initialize an ilk without liquidations
    function initIlk(
        bytes32 ilk,
        address join,
        address pip
    ) public {
        vat.init(ilk);
        jug.init(ilk);

        vat.rely(join);

        spotter.file(ilk, "pip", pip);
        spotter.file(ilk, "mat", RAY);
        spotter.poke(ilk);
    }

    /// @dev Initialize an ilk with liquidations
    function initIlk(
        bytes32 ilk,
        address join,
        address pip,
        address clip,
        address clipCalc
    ) public {
        initIlk(ilk, join, pip);

        // TODO liquidations
    }

    /// @dev Give who a ward on all core contracts
    function giveAdminAccess(address who) public {
        if (vat != address(0)) GodMode.setWard(address(vat), who, 1);
        if (daiJoin != address(0)) GodMode.setWard(address(daiJoin), who, 1);
        if (vow != address(0)) GodMode.setWard(address(vow), who, 1);
        if (dog != address(0)) GodMode.setWard(address(dog), who, 1);
        if (pot != address(0)) GodMode.setWard(address(pot), who, 1);
        if (jug != address(0)) GodMode.setWard(address(jug), who, 1);
        if (spotter != address(0)) GodMode.setWard(address(spotter), who, 1);
        if (cure != address(0)) GodMode.setWard(address(cure), who, 1);
    }

    /// @dev Give who a ward on all core contracts to both caller and this MCD instance
    function giveAdminAccess() public {
        giveAdminAccess(address(this));
        giveAdminAccess(address(msg.sender));
    }

    function newUser() public returns (MCDUser) {
        return new MCDUser(this);
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
