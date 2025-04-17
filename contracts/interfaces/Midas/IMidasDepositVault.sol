// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IMidasManageableVault.sol";

interface IMidasDepositVault is IMidasManageableVault {
    function depositInstant(
        address tokenIn,
        uint256 amountToken,
        uint256 minReceiveAmount,
        bytes32 referrerId
    ) external;
}
