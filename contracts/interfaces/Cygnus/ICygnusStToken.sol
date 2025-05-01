// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICygnusStToken {
    function mint(address _referral, uint256 _assetsAmount) external returns (uint256 sharesAmount);

    function convertToAssets(uint256 _sharesAmount) external view returns (uint256);

    function previewDeposit(uint256 _assetsAmount) external view returns (uint256);

    function previewRedeem(uint256 _sharesAmount) external view returns (uint256);
}
