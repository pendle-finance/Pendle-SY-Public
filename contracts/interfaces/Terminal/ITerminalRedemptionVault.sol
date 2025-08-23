// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./ITerminalGenericVault.sol";

interface ITerminalRedemptionVault is ITerminalGenericVault {
    function redeemInstant(address tokenOut, uint256 amountMTokenIn, uint256 minReceiveAmount) external;
}
