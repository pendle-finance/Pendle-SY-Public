// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICentrifugeShareToken {
    function vault(address asset) external view returns (address);
}
