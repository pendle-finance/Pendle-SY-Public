// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStakedHYPEOverseer {
    function mint(address to) external payable returns (uint256 shares);
}
