// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;
import "./ITerminalGenericVault.sol";

interface ITerminalDepositVault is ITerminalGenericVault {
    function depositInstant(
        address tokenIn,
        uint256 amountToken,
        uint256 minReceiveAmount,
        bytes32 referrerId
    ) external;
}
