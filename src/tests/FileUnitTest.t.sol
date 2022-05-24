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

contract ValidFileContract {
    mapping (address => uint256) public wards;
    uint256 public someData;
    address public vow;
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event File(bytes32 indexed what, uint256 data);
    event File(bytes32 indexed what, address data);
    constructor() { wards[msg.sender] = 1; emit Rely(msg.sender); }
    modifier auth { require(wards[msg.sender] == 1, "FileContract/not-authorized"); _; }
    function rely(address usr) external auth { wards[usr] = 1; emit Rely(usr); }
    function deny(address usr) external auth { wards[usr] = 0; emit Deny(usr); }
    function file(bytes32 what, uint256 data) external auth {
        if (what == "someData") {
            someData = data;
        } else {
            revert("FileContract/file-unrecognized-param");
        }
        emit File(what, data);
    }
    function file(bytes32 what, address data) external auth {
        if (what == "vow") {
            vow = data;
        } else {
            revert("FileContract/file-unrecognized-param");
        }
        emit File(what, data);
    }
}
contract InvalidFileContractRevertName {
    mapping (address => uint256) public wards;
    uint256 public someData;
    address public vow;
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event File(bytes32 indexed what, uint256 data);
    event File(bytes32 indexed what, address data);
    constructor() { wards[msg.sender] = 1; emit Rely(msg.sender); }
    modifier auth { require(wards[msg.sender] == 1, "FileContract/not-authorized"); _; }
    function rely(address usr) external auth { wards[usr] = 1; emit Rely(usr); }
    function deny(address usr) external auth { wards[usr] = 0; emit Deny(usr); }
    function file(bytes32 what, uint256 data) external auth {
        if (what == "someData") {
            someData = data;
        } else {
            revert("BadName/file-unrecognized-param");
        }
        emit File(what, data);
    }
    function file(bytes32 what, address data) external auth {
        if (what == "vow") {
            vow = data;
        } else {
            revert("BadName/file-unrecognized-param");
        }
        emit File(what, data);
    }
}
contract InvalidFileContractMissingUpdate {
    mapping (address => uint256) public wards;
    uint256 public someData;
    address public vow;
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event File(bytes32 indexed what, uint256 data);
    event File(bytes32 indexed what, address data);
    constructor() { wards[msg.sender] = 1; emit Rely(msg.sender); }
    modifier auth { require(wards[msg.sender] == 1, "FileContract/not-authorized"); _; }
    function rely(address usr) external auth { wards[usr] = 1; emit Rely(usr); }
    function deny(address usr) external auth { wards[usr] = 0; emit Deny(usr); }
    function file(bytes32 what, uint256 data) external auth {
        if (what == "someData") {
        } else {
            revert("FileContract/file-unrecognized-param");
        }
        emit File(what, data);
    }
    function file(bytes32 what, address data) external auth {
        if (what == "vow") {
        } else {
            revert("FileContract/file-unrecognized-param");
        }
        emit File(what, data);
    }
}
contract InvalidFileContractMissingAuth {
    mapping (address => uint256) public wards;
    uint256 public someData;
    address public vow;
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event File(bytes32 indexed what, uint256 data);
    event File(bytes32 indexed what, address data);
    constructor() { wards[msg.sender] = 1; emit Rely(msg.sender); }
    modifier auth { require(wards[msg.sender] == 1, "FileContract/not-authorized"); _; }
    function rely(address usr) external auth { wards[usr] = 1; emit Rely(usr); }
    function deny(address usr) external auth { wards[usr] = 0; emit Deny(usr); }
    function file(bytes32 what, uint256 data) external {
        if (what == "someData") {
            someData = data;
        } else {
            revert("FileContract/file-unrecognized-param");
        }
        emit File(what, data);
    }
    function file(bytes32 what, address data) external {
        if (what == "vow") {
            vow = data;
        } else {
            revert("FileContract/file-unrecognized-param");
        }
        emit File(what, data);
    }
}

contract FileUnitTest is DSSTest {

    function test_file_uint_valid() public {
        checkFileUint(address(new ValidFileContract()), "FileContract", ["someData"]);
    }
    function testFail_file_uint_revert_name() public {
        checkFileUint(address(new InvalidFileContractRevertName()), "FileContract", ["someData"]);
    }
    function testFail_file_uint_missing_update() public {
        checkFileUint(address(new InvalidFileContractMissingUpdate()), "FileContract", ["someData"]);
    }
    function testFail_file_uint_missing_auth() public {
        checkFileUint(address(new InvalidFileContractMissingAuth()), "FileContract", ["someData"]);
    }

    function test_file_address_valid() public {
        checkFileAddress(address(new ValidFileContract()), "FileContract", ["vow"]);
    }
    function testFail_file_address_revert_name() public {
        checkFileAddress(address(new InvalidFileContractRevertName()), "FileContract", ["vow"]);
    }
    function testFail_file_address_missing_update() public {
        checkFileAddress(address(new InvalidFileContractMissingUpdate()), "FileContract", ["vow"]);
    }
    function testFail_file_address_missing_auth() public {
        checkFileAddress(address(new InvalidFileContractMissingAuth()), "FileContract", ["vow"]);
    }

}
