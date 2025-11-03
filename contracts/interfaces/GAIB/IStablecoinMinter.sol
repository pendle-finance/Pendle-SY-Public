// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

interface IStablecoinMinter {
    function aid() external view returns (address);
    function stablecoin() external view returns (address);
    function DECIMAL_ADJUSTMENT() external returns (uint256);
    function mint(uint256 stablecoinAmount) external returns (uint256);
}
