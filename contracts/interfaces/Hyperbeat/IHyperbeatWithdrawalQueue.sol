// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IHyperbeatWithdrawalQueue {
    function instantWithdrawalFee() external view returns (uint64);
    function isInstantWithdrawalPaused() external view returns (bool);
    function instantWithdraw(address _user, uint256 _amount) external;
}
