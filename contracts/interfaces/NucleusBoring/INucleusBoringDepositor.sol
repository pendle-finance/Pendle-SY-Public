// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INucleusBoringDepositor {
    function deposit(
        address depositAsset,
        uint256 depositAmount,
        uint256 minimumMint,
        address to,
        bytes calldata communityCode
    ) external returns (uint256 shares);

    function depositNative(
        uint256 depositAmount,
        uint256 minimumMint,
        address to,
        bytes calldata communityCode
    ) external payable returns (uint256 shares);
}