// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

interface ITerminalGenericVault {
    struct TokenConfig {
        address dataFeed;
        uint256 fee;
        uint256 allowance;
        bool stable;
    }

    function mToken() external view returns (address);

    function mTokenDataFeed() external view returns (address);

    function tokensConfig(address token) external view returns (TokenConfig memory);

    function instantFee() external view returns (uint256);

    function waivedFeeRestriction(address account) external view returns (bool);
}
