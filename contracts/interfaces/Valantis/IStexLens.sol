// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStexLens {
    function getTotalValueToken1(address stex) external view returns (uint256 totalValueToken1);
    function getSharesForDeposit(address stex, uint256 amount) external view returns (uint256);
    function getAmountsForWithdraw(
        address stex,
        uint256 shares,
        bool isInstantWithdrawal
    ) external view returns (uint256, uint256);
}
