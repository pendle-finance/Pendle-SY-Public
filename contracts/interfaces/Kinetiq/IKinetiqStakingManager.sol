// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IKinetiqStakingManager {
    function stake() external payable;

    function stakingLimit() external view returns (uint256);

    function maxStakeAmount() external view returns (uint256);

    function minStakeAmount() external view returns (uint256);

    function totalStaked() external view returns (uint256);

    function totalClaimed() external view returns (uint256);
}
