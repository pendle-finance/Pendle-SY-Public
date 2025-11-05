// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IStrataTranche {
    function cdo() external view returns (address);
    function redeem(address token, uint256 shares, address receiver, address owner) external returns (uint256);
}
