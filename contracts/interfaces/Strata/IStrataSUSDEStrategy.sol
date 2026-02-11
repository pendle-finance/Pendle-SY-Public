// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IStrataSUSDEStrategy {
    function sUSDeCooldownJrt() external view returns (uint256);
    function sUSDeCooldownSrt() external view returns (uint256);
}
