// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IStakedNukeStaking {
    function nuke() external view returns (address);

    function stakedNuke() external view returns (address);

    function stake(address to, uint256 amount) external returns (uint256);

    function unstake(address to, uint256 amount) external returns (uint256);

    function rebase() external;

    function epoch() external view returns (uint64 length, uint64 number, uint64 end, uint256 distribute);
}
