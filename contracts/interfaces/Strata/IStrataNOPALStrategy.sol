// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IStrataNOPALStrategy {
    function nOpalCooldownJrt() external view returns (uint256);
    function nOpalCooldownSrt() external view returns (uint256);
}
