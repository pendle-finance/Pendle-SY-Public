// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IStrataTranche {
    function cdo() external view returns (address);
    function deposit(address token, uint256 tokenAmount, address receiver) external returns (uint256);
    function redeem(address token, uint256 shares, address receiver, address owner) external returns (uint256);
    function previewDeposit(address token, uint256 tokenAmount) external view returns (uint256);
    function previewRedeem(address token, uint256 shares) external view returns (uint256);
    function convertToAssets(uint256 shares) external view returns (uint256);
}
