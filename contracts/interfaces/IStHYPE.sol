// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStHYPE {
    function balanceToShares(uint256 balance) external view returns (uint256);
    function sharesToBalance(uint256 shares) external view returns (uint256);
}
