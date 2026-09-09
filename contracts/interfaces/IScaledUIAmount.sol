// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IScaledUIAmount {
    event UIMultiplierUpdated(uint256 oldMultiplier, uint256 newMultiplier, uint256 effectiveAtTimestamp);

    function uiMultiplier() external view returns (uint256);
}
