// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IHyperbeatDepositor {
    function isDepositToken(address token) external view returns (bool);
    function depositFee() external view returns (uint256);
    function depositCap() external view returns (uint256);
    function depositFeeRecipient() external view returns (address);

    function deposit(address _token, address _receiver, uint256 _amount, bytes32 _builderCode) external;
}
