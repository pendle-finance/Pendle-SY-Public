// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IEnableOnlyAssetsWhitelist.sol";

interface ITokenizedVault {
    function deposit(address assetIn, uint256 amountIn, address receiverAddr) external returns (uint256 shares);

    function instantRedeem(uint256 shares, address receiverAddr) external;

    function getSharePrice() external view returns (uint256);

    function previewDeposit(address assetIn, uint256 amountIn) external view returns (uint256, uint256);

    function previewRedemption(
        uint256 shares,
        bool isInstant
    ) external view returns (uint256 assetsAmount, uint256 assetsAfterFee);

    function assetsWhitelistAddress() external view returns (IEnableOnlyAssetsWhitelist);

    function asset() external view returns (address);

    function getTotalAssets() external view returns (uint256);

    function maxDepositAmount() external view returns (uint256);

    function depositCap() external view returns (uint256);

    function maxWithdrawalAmount() external view returns (uint256);
}
