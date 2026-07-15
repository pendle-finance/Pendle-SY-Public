// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IPMorphoMarketWrapper {
    function deposit(uint256 assets) external returns (uint256 shares);

    function redeem(uint256 shares, address receiver) external returns (uint256 assets);

    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    function exchangeRate() external view returns (uint256);

    function loanToken() external view returns (address);
}
