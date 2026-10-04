// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface ISyntheticSharesOracle {
    function getSValue(address asset) external view returns (uint128 sValue, bool paused);
}
