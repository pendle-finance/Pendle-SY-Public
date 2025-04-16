// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.23;

import "../../SYBase.sol";
import "../../../../interfaces/Midas/IDepositVault.sol";
import "../../../../interfaces/Midas/IRedemptionVault.sol";
import "./libraries/DecimalsCorrectionLibrary.sol";
import "./libraries/MidasAdapterLib.sol";

contract PendleMidasSY is SYBase {
    using DecimalsCorrectionLibrary for uint256;
    using PMath for uint256;

    bytes32 constant PENDLE_REFERRER_ID = keccak256("midas.referrers.pendle");

    address public immutable depositVault;
    address public immutable redemptionVault;
    address public immutable mTokenDataFeed;

    constructor(
        string memory _name,
        string memory _symbol,
        address _mToken,
        address _depositVault,
        address _redemptionVault,
        address _mTokenDataFeed
    ) SYBase(_name, _symbol, _mToken) {
        depositVault = _depositVault;
        redemptionVault = _redemptionVault;
        mTokenDataFeed = _mTokenDataFeed;

        _safeApproveInf(_mToken, redemptionVault);
    }

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 /*amountSharesOut*/) {
        uint256 balanceBefore = _selfBalance(IERC20(yieldToken));
        _safeApproveInf(tokenIn, depositVault);
        IDepositVault(depositVault).depositInstant(
            tokenIn,
            MidasAdapterLib.tokenAmountToBase18(tokenIn, amountDeposited),
            0,
            PENDLE_REFERRER_ID
        );
        return _selfBalance(IERC20(yieldToken)) - balanceBefore;
    }

    function _redeem(
        address receiver,
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal override returns (uint256 amountTokenOut) {
        uint256 balanceBefore = _selfBalance(IERC20(tokenOut));
        // no need to approve as it was already done in the constructor
        IRedemptionVault(redemptionVault).redeemInstant(tokenOut, amountSharesToRedeem, 0);
        amountTokenOut = balanceBefore - _selfBalance(IERC20(tokenOut));
        _transferOut(tokenOut, receiver, amountTokenOut);
    }

    function exchangeRate() public view virtual override returns (uint256) {
        return PMath.ONE;
    }

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view override returns (uint256 /*amountSharesOut*/) {
        return MidasAdapterLib.estimateAmountOutDeposit(depositVault, mTokenDataFeed, tokenIn, amountTokenToDeposit);
    }

    function _previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal view override returns (uint256 /*amountTokenOut*/) {
        return MidasAdapterLib.estimateAmountOutRedeem(redemptionVault, mTokenDataFeed, tokenOut, amountSharesToRedeem);
    }

    function getTokensIn() public view override returns (address[] memory res) {
        return IManageableVault(depositVault).getPaymentTokens();
    }

    function getTokensOut() public view override returns (address[] memory res) {
        return IManageableVault(redemptionVault).getPaymentTokens();
    }

    function isValidTokenIn(address token) public view override returns (bool) {
        return IManageableVault(depositVault).tokensConfig(token).dataFeed != address(0);
    }

    function isValidTokenOut(address token) public view override returns (bool) {
        return IManageableVault(redemptionVault).tokensConfig(token).dataFeed != address(0);
    }

    function assetInfo() external view returns (AssetType assetType, address assetAddress, uint8 assetDecimals) {
        return (AssetType.TOKEN, yieldToken, MidasAdapterLib.getTokenDecimals(yieldToken));
    }
}
