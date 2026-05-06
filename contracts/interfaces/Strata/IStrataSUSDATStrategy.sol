// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IStrataSUSDATStrategy {
    function sUSDatCooldownJrt() external view returns (uint256);
    function sUSDatCooldownSrt() external view returns (uint256);
}
