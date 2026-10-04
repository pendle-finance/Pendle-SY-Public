// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOraclePausable {
    function oraclePaused() external view returns (bool);
}
