// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMidasDataFeed {
    function getDataInBase18() external view returns (uint256 answer);
}
