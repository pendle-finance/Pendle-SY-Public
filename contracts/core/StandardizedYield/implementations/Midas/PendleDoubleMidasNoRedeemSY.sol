// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.23;

import "./PendleMidasSY.sol";

contract PendleDoubleMidasNoRedeemSY is PendleMidasSY {
    using ArrayLib for address[];

    address public immutable underlyingDepositVault;
    address public immutable underlyingTokenDataFeed;

    constructor(
        address _mToken,
        address _depositVault,
        address _redemptionVault,
        address _mTokenDataFeed,
        address _underlying,
        address _underlyingDepositVault,
        address _underlyingTokenDataFeed
    ) PendleMidasSY(_mToken, _depositVault, _redemptionVault, _mTokenDataFeed, _underlying) {
        underlyingDepositVault = _underlyingDepositVault;
        underlyingTokenDataFeed = _underlyingTokenDataFeed;
    }

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == yieldToken) {
            return amountDeposited;
        }

        if (tokenIn != underlying) {
            (tokenIn, amountDeposited) = (
                underlying,
                _depositMidas(underlyingDepositVault, tokenIn, amountDeposited, underlying)
            );
        }

        return _depositMidas(depositVault, tokenIn, amountDeposited, yieldToken);
    }

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view override returns (uint256 amountSharesOut) {
        if (tokenIn == yieldToken) {
            return amountTokenToDeposit;
        }

        if (tokenIn != underlying) {
            (tokenIn, amountTokenToDeposit) = (
                underlying,
                MidasAdapterLib.estimateAmountOutDeposit(
                    underlyingDepositVault,
                    underlyingTokenDataFeed,
                    tokenIn,
                    amountTokenToDeposit
                )
            );
        }

        return MidasAdapterLib.estimateAmountOutDeposit(depositVault, mTokenDataFeed, tokenIn, amountTokenToDeposit);
    }

    function getTokensIn() public view override returns (address[] memory res) {
        return
            IMidasManageableVault(underlyingDepositVault).getPaymentTokens().appendHead(underlying).appendHead(
                yieldToken
            );
    }

    function getTokensOut() public view virtual override returns (address[] memory res) {
        return ArrayLib.create(yieldToken);
    }

    function isValidTokenIn(address token) public view virtual override returns (bool) {
        return
            token == yieldToken ||
            token == underlying ||
            IMidasManageableVault(underlyingDepositVault).tokensConfig(token).dataFeed != address(0);
    }

    function isValidTokenOut(address token) public view virtual override returns (bool) {
        return token == yieldToken;
    }

    function _depositMidas(
        address _depositVault,
        address _tokenIn,
        uint256 _amountDeposited,
        address _tokenOut
    ) internal returns (uint256 amountOut) {
        uint256 _balanceBefore = _selfBalance(_tokenOut);
        _safeApproveInf(_tokenIn, _depositVault);
        IMidasDepositVault(_depositVault).depositInstant(
            _tokenIn,
            MidasAdapterLib.tokenAmountToBase18(_tokenIn, _amountDeposited),
            0,
            PENDLE_REFERRER_ID()
        );
        return _selfBalance(_tokenOut) - _balanceBefore;
    }
}
