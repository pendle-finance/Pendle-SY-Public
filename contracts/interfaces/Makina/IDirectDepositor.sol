// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDirectDepositor {
    function machine() external view returns (address);

    function deposit(
        uint256 assets,
        address receiver,
        uint256 minShares,
        bytes32 referralKey
    ) external returns (uint256);
}
