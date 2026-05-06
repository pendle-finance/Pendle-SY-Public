// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IInstantUnstaking {
    function instantUnstake(uint256 _sNusdAmount, uint256 _minNusdOut) external returns (uint256);
    function quoteInstantUnstake(
        address _account,
        uint256 _snusdAmount
    ) external view returns (uint256 nusdOut, uint256 feeAmount);
}
