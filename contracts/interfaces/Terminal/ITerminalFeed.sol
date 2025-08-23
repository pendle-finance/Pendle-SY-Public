// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

interface ITerminalFeed {
    function getDataInBase18() external view returns (uint256 answer);
}
