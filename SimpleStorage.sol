// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleStorage {
    uint256 public value;

    function setValue(uint256 _v) external  {
        value = _v;
    }

    function getValue() external view returns(uint256) {
        return value;
    }
}
