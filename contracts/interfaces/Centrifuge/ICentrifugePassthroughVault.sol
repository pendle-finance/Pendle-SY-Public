// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICentrifugePassthroughVault {
    function asset() external view returns (address);

    function share() external view returns (address);

    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    function previewDeposit(uint256 assets) external view returns (uint256);

    function maxDeposit(address controller) external view returns (uint256);
}
