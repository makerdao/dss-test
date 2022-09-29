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

import {stdJson} from "forge-std/StdJson.sol";
import {ChainlogAbstract} from "dss-interfaces/Interfaces.sol";

import {MCD} from "../MCD.sol";
import {GodMode,Vm} from "../GodMode.sol";

contract Domain {

    using stdJson for string;

    string public config;
    string public name;
    MCD public mcd;
    Vm public vm;
    uint256 public forkId;

    constructor(string memory _config, string memory _name) {
        config = _config;
        name = _name;
        vm = GodMode.vm();
        string memory rpc = vm.envString(config.readString(string.concat(".domains.", name, ".rpc")));
        if (bytes(rpc).length == 0) revert(string.concat("Environment variable '", rpc, "' is not defined."));
        forkId = vm.createFork(rpc);
        vm.makePersistent(address(this));
    }

    function loadMCDFromChainlog() public {
        mcd = new MCD();
        mcd.loadFromChainlog(ChainlogAbstract(config.readAddress(string.concat(".domains.", name, ".chainlog"))));
    }
    
    function selectFork() public {
        vm.selectFork(forkId);
    }

}
