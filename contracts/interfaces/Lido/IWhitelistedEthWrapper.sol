// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWhitelistedEthWrapper {
    function deposit(
        address depositToken,
        uint256 amount,
        address vault,
        address receiver,
        address referral
    ) external payable returns (uint256 shares);

    function WETH() external returns (address);
    function wstETH() external returns (address);

    function redeem(uint256 shares, address receiver, address owner) external returns (uint256);
}
