// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IWrappedRewardToken {
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);

    function previewRedeem(
        uint256 shares
    ) external view returns (uint256);

    function balanceOf(address) external returns (uint256);
}
