// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPExternalCapGates {
    function getAbsoluteSupplyCap(address sy) external view returns (uint256);
    function getAbsoluteTotalSupply(address sy) external view returns (uint256);
}
