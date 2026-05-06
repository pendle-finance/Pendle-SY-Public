// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IXPRISM {
    function stake(uint256 _amount, uint256 _minSharesOut) external returns (uint256);
}
