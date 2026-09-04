// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IStakedNetStaking {
    function net() external view returns (address);

    function sNet() external view returns (address);

    function stake(address to, uint256 amount) external returns (uint256);

    function unstake(address to, uint256 amount) external returns (uint256);

    function epoch() external view returns (uint64 length, uint64 number, uint64 end, uint256 distribute);
}
