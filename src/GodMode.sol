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

import {
    WardsAbstract,
    DSTokenAbstract,
    DaiAbstract,
    VatAbstract
} from "dss-interfaces/Interfaces.sol";
import {Vm} from "forge-std/Vm.sol";

library GodMode {
    
    address constant public VM_ADDR = address(bytes20(uint160(uint256(keccak256('hevm cheat code')))));

    function vm() internal pure returns (Vm) {
        return Vm(VM_ADDR);
    }

    /// @dev Set the ward for `base` for the specified `target`
    /// Note this only works for contracts compiled under Solidity. Vyper contracts use a different storage structure for maps.
    /// See https://twitter.com/msolomon44/status/1420137730009300992?t=WO2052xM3AzUCL7o7Pfkow&s=19
    function setWard(address base, address target, uint256 val) internal {

        // Edge case - ward is already set
        if (WardsAbstract(base).wards(target) == val) return;

        for (int i = 0; i < 100; i++) {
            // Scan the storage for the ward storage slot
            bytes32 prevValue = vm().load(
                address(base),
                keccak256(abi.encode(target, uint256(i)))
            );
            vm().store(
                address(base),
                keccak256(abi.encode(target, uint256(i))),
                bytes32(uint256(val))
            );
            if (WardsAbstract(base).wards(target) == val) {
                // Found it
                return;
            } else {
                // Keep going after restoring the original value
                vm().store(
                    address(base),
                    keccak256(abi.encode(target, uint256(i))),
                    prevValue
                );
            }
        }

        // We have failed if we reach here
        revert("Could not give auth access");
    }

    /// @dev Set the ward for `base` for the specified `target`
    /// Note this only works for contracts compiled under Solidity. Vyper contracts use a different storage structure for maps.
    /// See https://twitter.com/msolomon44/status/1420137730009300992?t=WO2052xM3AzUCL7o7Pfkow&s=19
    function setWard(WardsAbstract base, address target, uint256 val) internal {
        setWard(address(base), target, val);
    }

    /// @dev Set the ward for `base` for the specified `target`
    /// Note this only works for contracts compiled under Solidity. Vyper contracts use a different storage structure for maps.
    /// See https://twitter.com/msolomon44/status/1420137730009300992?t=WO2052xM3AzUCL7o7Pfkow&s=19
    function setWard(VatAbstract base, address target, uint256 val) internal {
        setWard(address(base), target, val);
    }

    /// @dev Sets the balance for `who` to `amount` for `token`.
    /// Note this only works for contracts compiled under Solidity. Vyper contracts use a different storage structure for maps.
    /// See https://twitter.com/msolomon44/status/1420137730009300992?t=WO2052xM3AzUCL7o7Pfkow&s=19
    function setBalance(address token, address who, uint256 amount) internal {
        // Edge case - balance is already set for some reason
        if (DSTokenAbstract(token).balanceOf(who) == amount) return;

        for (uint256 i = 0; i < 200; i++) {
            // Scan the storage for the balance storage slot
            bytes32 prevValue = vm().load(
                token,
                keccak256(abi.encode(who, uint256(i)))
            );
            vm().store(
                token,
                keccak256(abi.encode(who, uint256(i))),
                bytes32(amount)
            );
            if (DSTokenAbstract(token).balanceOf(who) == amount) {
                // Found it
                return;
            } else {
                // Keep going after restoring the original value
                vm().store(
                    token,
                    keccak256(abi.encode(who, uint256(i))),
                    prevValue
                );
            }
        }

        // We have failed if we reach here
        revert("Could not give tokens");
    }

    /// @dev Sets the balance for `who` to `amount` for `token`.
    /// Note this only works for contracts compiled under Solidity. Vyper contracts use a different storage structure for maps.
    /// See https://twitter.com/msolomon44/status/1420137730009300992?t=WO2052xM3AzUCL7o7Pfkow&s=19
    function setBalance(DSTokenAbstract token, address who, uint256 amount) internal {
        setBalance(address(token), who, amount);
    }

    /// @dev Sets the balance for `who` to `amount` for `token`.
    /// Note this only works for contracts compiled under Solidity. Vyper contracts use a different storage structure for maps.
    /// See https://twitter.com/msolomon44/status/1420137730009300992?t=WO2052xM3AzUCL7o7Pfkow&s=19
    function setBalance(DaiAbstract token, address who, uint256 amount) internal {
        setBalance(address(token), who, amount);
    }

}
