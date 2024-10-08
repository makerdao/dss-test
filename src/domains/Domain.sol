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

import { stdJson } from "forge-std/StdJson.sol";
import { StdChains } from "forge-std/StdChains.sol";
import { Vm } from "forge-std/Vm.sol";

import { MCD, DssInstance } from "../MCD.sol";

contract Domain {

    using stdJson for string;

    Vm internal constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    string public config;
    StdChains.Chain private _details;
    DssInstance private _dss;
    uint256 public forkId;

    constructor(string memory _config, StdChains.Chain memory _chain) {
        config = _config;
        _details = _chain;
        forkId = vm.createFork(_chain.rpcUrl);
        vm.makePersistent(address(this));
    }

    function hasConfigKey(string memory key) public view returns (bool) {
        bytes memory raw = config.parseRaw(string.concat(".domains.", _details.chainAlias, ".", key));
        return raw.length > 0;
    }

    function readConfigString(string memory key) public view returns (string memory) {
        return config.readString(string.concat(".domains.", _details.chainAlias, ".", key));
    }

    function readConfigAddress(string memory key) public view returns (address) {
        return config.readAddress(string.concat(".domains.", _details.chainAlias, ".", key));
    }

    function readConfigAddresses(string memory key) public view returns (address[] memory) {
        return config.readAddressArray(string.concat(".domains.", _details.chainAlias, ".", key));
    }

    function readConfigUint(string memory key) public view returns (uint256) {
        return config.readUint(string.concat(".domains.", _details.chainAlias, ".", key));
    }

    function readConfigInt(string memory key) public view returns (int256) {
        return config.readInt(string.concat(".domains.", _details.chainAlias, ".", key));
    }

    function readConfigBytes32(string memory key) public view returns (bytes32) {
        return config.readBytes32(string.concat(".domains.", _details.chainAlias, ".", key));
    }

    function bytesToBytes32(bytes memory b) private pure returns (bytes32) {
        bytes32 out;
        for (uint256 i = 0; i < b.length; i++) {
            out |= bytes32(b[i] & 0xFF) >> (i * 8);
        }
        return out;
    }

    function readConfigBytes32FromString(string memory key) public view returns (bytes32) {
        return bytesToBytes32(bytes(readConfigString(key)));
    }

    function loadDssFromChainlog() public {
        _dss = MCD.loadFromChainlog(readConfigAddress("chainlog"));
    }

    function dss() public view returns (DssInstance memory) {
        return _dss;
    }

    function details() public view returns (StdChains.Chain memory) {
        return _details;
    }

    function selectFork() public {
        vm.selectFork(forkId);
        require(block.chainid == _details.chainId, string(abi.encodePacked(_details.chainAlias, " is pointing to the wrong RPC endpoint '", _details.rpcUrl, "'")));
    }

    function rollFork(uint256 blocknum) public {
        vm.rollFork(forkId, blocknum);
    }

}
