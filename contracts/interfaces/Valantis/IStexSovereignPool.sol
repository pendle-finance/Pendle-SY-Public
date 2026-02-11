// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStexSovereignPool {
    function isToken0Rebase() external view returns (bool);
    function isToken1Rebase() external view returns (bool);
}