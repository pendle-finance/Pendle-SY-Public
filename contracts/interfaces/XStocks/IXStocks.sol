// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IXStocks {
    function getSharesByUnderlyingAmount(uint256 _underlyingAmount) external view returns (uint256);

    function getUnderlyingAmountByShares(uint256 _sharesAmount) external view returns (uint256);
}
