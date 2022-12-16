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

import {stdJson} from "forge-std/StdJson.sol";
import {ChainlogAbstract} from "dss-interfaces/Interfaces.sol";

import {MCD,DssInstance} from "../MCD.sol";
import {GodMode,Vm} from "../GodMode.sol";

contract Domain {

    using stdJson for string;

    DssInstance private _dss;

    string  public config;
    string  public name;
    Vm      public vm;
    uint256 public forkId;
    uint256 public live = 0;

    constructor(string memory _config, string memory _name) {
        config = _config;
        name = _name;
        vm = GodMode.vm();
    }

    function readConfigString(string memory key) public returns (string memory) {
        return config.readString(string.concat(".domains.", name, ".", key));
    }

    function readConfigAddress(string memory key) public returns (address) {
        return config.readAddress(string.concat(".domains.", name, ".", key));
    }

    function readConfigUint(string memory key) public returns (uint256) {
        return config.readUint(string.concat(".domains.", name, ".", key));
    }

    function readConfigInt(string memory key) public returns (int256) {
        return config.readInt(string.concat(".domains.", name, ".", key));
    }

    function readConfigBytes32(string memory key) public returns (bytes32) {
        return config.readBytes32(string.concat(".domains.", name, ".", key));
    }

    function bytesToBytes32(bytes memory b) private pure returns (bytes32) {
        bytes32 out;
        for (uint256 i = 0; i < b.length; i++) {
            out |= bytes32(b[i] & 0xFF) >> (i * 8);
        }
        return out;
    }

    function readConfigBytes32FromString(string memory key) public returns (bytes32) {
        return bytesToBytes32(bytes(readConfigString(key)));
    }

    function loadDssFromChainlog() public {
        _dss = MCD.loadFromChainlog(readConfigAddress("chainlog"));
    }

    function dss() public view returns (DssInstance memory) {
        return _dss;
    }

    function loadFork(uint256 _forkId) public {
        forkId = _forkId;
        live = 1;
        vm.makePersistent(address(this));
    }

    function loadConfig() public virtual {
        string memory rpcEnv = readConfigString("rpc");
        string memory rpc = vm.envString(rpcEnv);
        if (bytes(rpc).length > 0) {
            live = 1;
            forkId = vm.createFork(rpc);
            uint256 domainBlock = vm.envUint(readConfigString("block"));
            if (domainBlock > 0) {
                rollFork(domainBlock);
            }
            vm.makePersistent(address(this));
        }
    }

    function selectFork() public {
        vm.selectFork(forkId);
    }

    function rollFork(uint256 blockNum) public {
        vm.rollFork(forkId, blockNum);
    }
}
