// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IManageableVault {
    struct TokenConfig {
        address dataFeed;
        uint256 fee;
        uint256 allowance;
        bool stable;
    }

    function getPaymentTokens() external view returns (address[] memory);

    function tokensConfig(address token) external view returns (TokenConfig memory);

    function instantFee() external view returns (uint256);

    function waivedFeeRestriction(address sender) external view returns (bool);
}
