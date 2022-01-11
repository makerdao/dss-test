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
import "./GodMode.sol";
import "./MCD.sol";

/// @dev A user which can perform actions in MCD
contract MCDUser {

    using GodMode for DSTokenAbstract;

    MCD mcd;

    constructor(
        MCD _mcd
    ) public {
        mcd = _mcd;
    }

    /// @dev Create an auction on the provided ilk
    /// @param join The gem join adapter to use
    /// @param amount The amount of gems to use as collateral
    function createAuction(
        GemJoinAbstract join,
        uint256 amount
    ) public {
        DSTokenAbstract token = DSTokenAbstract(join.gem());
        bytes32 ilk = join.ilk();

        token.giveTokens(address(this), amount);
        uint256 prevAllowance = token.allowance(address(this), address(join));
        token.approve(address(join), amount);
        join.join(address(this), amount);
        token.approve(address(join), prevAllowance);
        (,uint256 rate, uint256 spot,,) = mcd.vat().ilks(ilk);
        uint256 art = spot * amount / rate;
        uint256 ink = amount * (10 ** (18 - token.decimals()));
        mcd.vat().frob(ilk, address(this), address(this), address(this), int256(ink), int256(art));

        // Temporarily increase the liquidation threshold to liquidate this one vault then reset it
        mcd.vat().file(ilk, "spot", spot + 1);
        mcd.dog().bark(ilk, address(this), address(this));
        mcd.vat().file(ilk, "spot", spot);
    }

}
