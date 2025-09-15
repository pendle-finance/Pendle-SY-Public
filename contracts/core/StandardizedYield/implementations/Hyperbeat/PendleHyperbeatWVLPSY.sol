// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Midas/PendleMidasSY.sol";
import "../../../../interfaces/IPTokenWithSupplyCap.sol";

contract PendleHyperbeatWVLPSY is PendleMidasSY, IPTokenWithSupplyCap {
    using DecimalsCorrectionLibrary for uint256;

    error HyperbeatWVLPAssetLimitExceeded(address tokenIn, uint256 tokenLimit, uint256 amountDeposited);

    address public constant USDT0 = 0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb;
    address public constant wVLP = 0xD66d69c288d9a6FD735d7bE8b2e389970fC4fD42;
    address public constant wVLPDepositVault = 0xc800f672EE8693BC0138E513038C84fe2D1B8a78;
    address public constant wVLPRedemptionVault = 0x462B95575cb2D56de9d1aAaAAb452279B058Aa06;
    address public constant wVLPDataFeed = 0x765FA39C3759408C383C18bb50F70efDcedB26A6;

    constructor() PendleMidasSY(wVLP, wVLPDepositVault, wVLPRedemptionVault, wVLPDataFeed, USDT0) {}

    /// @dev keccak256("hyperbeat.referrers.pendle")
    function PENDLE_REFERRER_ID() public pure override returns (bytes32) {
        return 0x2a176b24a5fec3af048070ad484d82fe4152c8b8eb2edc993ef5700c58ef3d53;
    }

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == yieldToken) {
            return amountTokenToDeposit;
        }

        IMidasDepositVault.TokenConfig memory tokenInConfig = IMidasDepositVault(depositVault).tokensConfig(tokenIn);
        uint256 tokenDecimals = IERC20Metadata(tokenIn).decimals();
        uint256 amountTokenToDepositBase18 = amountTokenToDeposit.convertToBase18(tokenDecimals);

        if (amountTokenToDepositBase18 > tokenInConfig.allowance) {
            revert HyperbeatWVLPAssetLimitExceeded(
                tokenIn,
                tokenInConfig.allowance.convertFromBase18(tokenDecimals),
                amountTokenToDeposit
            );
        }

        return MidasAdapterLib.estimateAmountOutDeposit(depositVault, mTokenDataFeed, tokenIn, amountTokenToDeposit);
    }

    function getTokensOut() public pure override returns (address[] memory res) {
        return ArrayLib.create(wVLP);
    }

    function isValidTokenOut(address token) public pure override returns (bool) {
        return token == wVLP;
    }

    function getAbsoluteSupplyCap() external view override returns (uint256) {
        address[] memory tokensIn = IMidasManageableVault(depositVault).getPaymentTokens();
        uint256 tokensInLength = tokensIn.length;
        uint256 totalAmountMTokenCanMint = 0;

        for (uint256 i = 0; i < tokensInLength; ) {
            IMidasDepositVault.TokenConfig memory tokenInConfig = IMidasDepositVault(depositVault).tokensConfig(
                tokensIn[i]
            );
            uint256 tokenInDecimals = IERC20Metadata(tokensIn[i]).decimals();

            totalAmountMTokenCanMint += MidasAdapterLib.estimateAmountOutDeposit(
                depositVault,
                mTokenDataFeed,
                tokensIn[i],
                tokenInConfig.allowance.convertFromBase18(tokenInDecimals)
            );

            unchecked {
                ++i;
            }
        }

        return _getAbsoluteTotalSupply() + totalAmountMTokenCanMint;
    }

    function getAbsoluteTotalSupply() external view override returns (uint256) {
        return _getAbsoluteTotalSupply();
    }

    function _getAbsoluteTotalSupply() internal view returns (uint256) {
        return IERC20(wVLP).totalSupply();
    }
}
