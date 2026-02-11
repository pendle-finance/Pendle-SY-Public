// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IStrataSNUSDStrategy {
    function sNUSDCooldownJrt() external view returns (uint256);
    function sNUSDCooldownSrt() external view returns (uint256);
}
