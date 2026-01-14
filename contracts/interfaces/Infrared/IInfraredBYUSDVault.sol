// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IInfraredBYUSDVault {
    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getRewardForUser(address _user) external;
}
