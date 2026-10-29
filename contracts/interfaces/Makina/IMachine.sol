// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMachine {
    function shareToken() external view returns (address);

    function accountingToken() external view returns (address);

    function maxMint() external view returns (uint256);

    function convertToShares(uint256 assets) external view returns (uint256);

    function convertToAssets(uint256 shares) external view returns (uint256);
}
