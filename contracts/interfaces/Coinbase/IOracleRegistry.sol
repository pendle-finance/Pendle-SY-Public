// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IOracleRegistry {
    function getOracleParams(address token) external view returns (uint256 multiplier, bool paused);
}
