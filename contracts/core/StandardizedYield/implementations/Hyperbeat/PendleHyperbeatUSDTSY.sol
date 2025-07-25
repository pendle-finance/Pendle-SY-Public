// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Midas/PendleMidasSY.sol";

contract PendleHyperbeatUSDTSY is PendleMidasSY {
    bytes32 public constant PENDLE_HYPERBEAT_REFERRER_ID = keccak256("hyperbeat.referrers.pendle");

    constructor(
        address _mToken,
        address _depositVault,
        address _redemptionVault,
        address _mTokenDataFeed,
        address _underlying
    ) PendleMidasSY(_mToken, _depositVault, _redemptionVault, _mTokenDataFeed, _underlying) {}

    function _deposit(address tokenIn, uint256 amountDeposited)
        internal
        virtual
        override
        returns (uint256 /*amountSharesOut*/ )
    {
        if (tokenIn == yieldToken) {
            return amountDeposited;
        }

        uint256 balanceBefore = _selfBalance(yieldToken);
        _safeApproveInf(tokenIn, depositVault);
        IMidasDepositVault(depositVault).depositInstant(
            tokenIn, MidasAdapterLib.tokenAmountToBase18(tokenIn, amountDeposited), 0, PENDLE_HYPERBEAT_REFERRER_ID
        );
        return _selfBalance(yieldToken) - balanceBefore;
    }
}
