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

import "../DSSTest.sol";

contract ValidAuthContract {
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    mapping (address => uint256) public wards;
    modifier auth { require(wards[msg.sender] == 1, "AuthContract/not-authorized"); _; }
    function rely(address usr) external auth { wards[usr] = 1; emit Rely(usr); }
    function deny(address usr) external auth { wards[usr] = 0; emit Deny(usr); }
    constructor() { wards[msg.sender] = 1; emit Rely(msg.sender); }
}
contract InvalidAuthContractRevertName {
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    mapping (address => uint256) public wards;
    modifier auth { require(wards[msg.sender] == 1, "BadName/not-authorized"); _; }
    function rely(address usr) external auth { wards[usr] = 1; emit Rely(usr); }
    function deny(address usr) external auth { wards[usr] = 0; emit Deny(usr); }
    constructor() { wards[msg.sender] = 1; emit Rely(msg.sender); }
}
contract InvalidAuthContractRely1 {
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    mapping (address => uint256) public wards;
    modifier auth { require(wards[msg.sender] == 1, "AuthContract/not-authorized"); _; }
    function rely(address usr) external auth { wards[usr] = 0; emit Rely(usr); }
    function deny(address usr) external auth { wards[usr] = 0; emit Deny(usr); }
    constructor() { wards[msg.sender] = 1; emit Rely(msg.sender); }
}
contract InvalidAuthContractRely2 {
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    mapping (address => uint256) public wards;
    modifier auth { require(wards[msg.sender] == 1, "AuthContract/not-authorized"); _; }
    function rely(address usr) external auth { wards[usr] = 1; emit Rely(msg.sender); }
    function deny(address usr) external auth { wards[usr] = 0; emit Deny(usr); }
    constructor() { wards[msg.sender] = 1; emit Rely(msg.sender); }
}
contract InvalidAuthContractRely3 {
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    mapping (address => uint256) public wards;
    modifier auth { require(wards[msg.sender] == 1, "AuthContract/not-authorized"); _; }
    function rely(address usr) external auth { wards[usr] = 1; emit Deny(usr); }
    function deny(address usr) external auth { wards[usr] = 0; emit Deny(usr); }
    constructor() { wards[msg.sender] = 1; emit Rely(msg.sender); }
}
contract InvalidAuthContractDeny1 {
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    mapping (address => uint256) public wards;
    modifier auth { require(wards[msg.sender] == 1, "AuthContract/not-authorized"); _; }
    function rely(address usr) external auth { wards[usr] = 1; emit Rely(usr); }
    function deny(address usr) external auth { wards[usr] = 1; emit Deny(usr); }
    constructor() { wards[msg.sender] = 1; emit Rely(msg.sender); }
}
contract InvalidAuthContractDeny2 {
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    mapping (address => uint256) public wards;
    modifier auth { require(wards[msg.sender] == 1, "AuthContract/not-authorized"); _; }
    function rely(address usr) external auth { wards[usr] = 1; emit Rely(usr); }
    function deny(address usr) external auth { wards[usr] = 0; emit Deny(msg.sender); }
    constructor() { wards[msg.sender] = 1; emit Rely(msg.sender); }
}
contract InvalidAuthContractDeny3 {
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    mapping (address => uint256) public wards;
    modifier auth { require(wards[msg.sender] == 1, "AuthContract/not-authorized"); _; }
    function rely(address usr) external auth { wards[usr] = 1; emit Rely(usr); }
    function deny(address usr) external auth { wards[usr] = 0; emit Rely(usr); }
    constructor() { wards[msg.sender] = 1; emit Rely(msg.sender); }
}

contract AuthUnitTest is DSSTest {

    function test_auth_valid() public {
        checkAuth(address(new ValidAuthContract()), "AuthContract");
    }
    function testFail_auth_revert_name() public {
        checkAuth(address(new InvalidAuthContractRevertName()), "AuthContract");
    }
    function testFail_auth_bad_rely1() public {
        checkAuth(address(new InvalidAuthContractRely1()), "AuthContract");
    }
    function testFail_auth_bad_rely2() public {
        checkAuth(address(new InvalidAuthContractRely2()), "AuthContract");
    }
    function testFail_auth_bad_rely3() public {
        checkAuth(address(new InvalidAuthContractRely3()), "AuthContract");
    }
    function testFail_auth_bad_deny1() public {
        checkAuth(address(new InvalidAuthContractDeny1()), "AuthContract");
    }
    function testFail_auth_bad_deny2() public {
        checkAuth(address(new InvalidAuthContractDeny2()), "AuthContract");
    }
    function testFail_auth_bad_deny3() public {
        checkAuth(address(new InvalidAuthContractDeny3()), "AuthContract");
    }

}
