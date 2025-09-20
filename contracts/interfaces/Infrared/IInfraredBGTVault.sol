// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IInfraredBGTVault {
    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getRewardForUser(address _user) external;

    function balanceOf(address account) external view returns (uint256);

    function earned(address account, address _rewardsToken) external view returns (uint256);
}
