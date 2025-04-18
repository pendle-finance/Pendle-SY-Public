// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../../../../../interfaces/Midas/IMidasManageableVault.sol";
import "../../../../../interfaces/Midas/IMidasDataFeed.sol";
import "../../../../libraries/math/PMath.sol";
import "./DecimalsCorrectionLibrary.sol";

library MidasAdapterLib {
    using DecimalsCorrectionLibrary for uint256;
    using PMath for uint256;

    uint256 private constant ONE_HUNDRED_PERCENT = 100 * 100;
    uint256 private constant STABLECOIN_RATE = 10 ** 18;

    function estimateAmountOutDeposit(
        address depositVault,
        address mTokenDataFeed,
        address tokenIn,
        uint256 amountTokenIn
    ) internal view returns (uint256) {
        uint8 tokenDecimals = getTokenDecimals(tokenIn);
        uint256 amountTokenInBase18 = tokenAmountToBase18(amountTokenIn, tokenDecimals);

        IMidasManageableVault.TokenConfig memory tokenConfig = IMidasManageableVault(depositVault).tokensConfig(
            tokenIn
        );

        uint256 tokenInRate = getTokenRate(tokenConfig.dataFeed, tokenConfig.stable);
        require(tokenInRate > 0, "tokenInRate zero");

        uint256 mTokenRate = getTokenRate(mTokenDataFeed, false);
        require(mTokenRate > 0, "mTokenRate zero");

        uint256 amountInUsd = (amountTokenInBase18 * tokenInRate) / PMath.ONE;

        uint256 feeTokenAmount = _truncate(
            _getFeeAmount(depositVault, tokenConfig, amountTokenInBase18),
            tokenDecimals
        );

        uint256 feeInUsd = (feeTokenAmount * tokenInRate) / PMath.ONE;
        uint256 amountInUsdWithoutFee = amountInUsd - feeInUsd;

        uint256 amountMToken = (amountInUsdWithoutFee * (PMath.ONE)) / mTokenRate;

        return amountMToken;
    }

    function estimateAmountOutRedeem(
        address redemptionVault,
        address mTokenDataFeed,
        address tokenOut,
        uint256 amountMTokenIn
    ) internal view returns (uint256 amountTokenOut) {
        IMidasManageableVault.TokenConfig memory tokenConfig = IMidasManageableVault(redemptionVault).tokensConfig(
            tokenOut
        );

        uint256 mTokenRate = getTokenRate(mTokenDataFeed, false);
        require(mTokenRate > 0, "mTokenRate zero");

        uint256 tokenOutRate = getTokenRate(tokenConfig.dataFeed, tokenConfig.stable);
        require(tokenOutRate > 0, "tokenOutRate zero");

        uint256 feeAmount = _getFeeAmount(redemptionVault, tokenConfig, amountMTokenIn);

        uint256 amountMTokenWithoutFee = amountMTokenIn - feeAmount;

        amountTokenOut = ((amountMTokenWithoutFee * mTokenRate) / tokenOutRate).convertFromBase18(
            getTokenDecimals(tokenOut)
        );
    }

    function getTokenRate(address dataFeed, bool stable) internal view returns (uint256) {
        uint256 rate = IMidasDataFeed(dataFeed).getDataInBase18();
        if (stable) return STABLECOIN_RATE;
        return rate;
    }

    function getTokenDecimals(address token) internal view returns (uint8) {
        return IERC20Metadata(token).decimals();
    }

    function tokenAmountToBase18(address token, uint256 amount) internal view returns (uint256) {
        return amount.convertToBase18(getTokenDecimals(token));
    }

    function tokenAmountToBase18(uint256 amount, uint8 decimals) internal pure returns (uint256) {
        return amount.convertToBase18(decimals);
    }

    function _truncate(uint256 value, uint8 decimals) private pure returns (uint256) {
        return value.convertFromBase18(decimals).convertToBase18(decimals);
    }

    function _getFeeAmount(
        address vault,
        IMidasManageableVault.TokenConfig memory tokenConfig,
        uint256 amount
    ) private view returns (uint256) {
        if (IMidasManageableVault(vault).waivedFeeRestriction(address(this))) return 0;

        uint256 feePercent;

        feePercent = tokenConfig.fee;

        feePercent += IMidasManageableVault(vault).instantFee();

        if (feePercent > ONE_HUNDRED_PERCENT) feePercent = ONE_HUNDRED_PERCENT;

        return (amount * feePercent) / ONE_HUNDRED_PERCENT;
    }
}
