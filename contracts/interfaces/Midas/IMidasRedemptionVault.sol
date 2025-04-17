// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IMidasManageableVault.sol";

interface IMidasRedemptionVault is IMidasManageableVault {
    function redeemInstant(address tokenOut, uint256 amountMTokenIn, uint256 minReceiveAmount) external;
}
