// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

interface IAaveStataToken {
    function depositATokens(uint256 assets, address receiver) external returns (uint256);

    function aToken() external view returns (address);
}
