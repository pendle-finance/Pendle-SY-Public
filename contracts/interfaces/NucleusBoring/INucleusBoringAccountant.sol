// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INucleusBoringAccountant {
    function getRateInQuoteSafe(address quote) external view returns (uint256);
}
