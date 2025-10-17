// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.23;

import "../../SYBaseUpg.sol";
import "../../../../interfaces/Midas/IMidasDepositVault.sol";
import "../../../../interfaces/Midas/IMidasRedemptionVault.sol";
import "./libraries/DecimalsCorrectionLibrary.sol";
import "./libraries/MidasAdapterLib.sol";

contract PendleMidasSY is SYBaseUpg {
    using DecimalsCorrectionLibrary for uint256;
    using PMath for uint256;

    // solhint-disable immutable-vars-naming
    address public immutable depositVault;
    address public immutable redemptionVault;
    address public immutable mTokenDataFeed;
    address public immutable underlying;

    uint256 public immutable yieldTokenUnit;
    uint256 public immutable underlyingUnit;

    constructor(
        address _mToken,
        address _depositVault,
        address _redemptionVault,
        address _mTokenDataFeed,
        address _underlying
    ) SYBaseUpg(_mToken) {
        depositVault = _depositVault;
        redemptionVault = _redemptionVault;
        mTokenDataFeed = _mTokenDataFeed;
        underlying = _underlying;

        yieldTokenUnit = 10 ** MidasAdapterLib.getTokenDecimals(_mToken);
        underlyingUnit = 10 ** MidasAdapterLib.getTokenDecimals(_underlying);
    }

    function initialize(string memory _name, string memory _symbol) external initializer {
        __SYBaseUpg_init(_name, _symbol);
        _safeApproveInf(yieldToken, redemptionVault);
    }

    /// @dev keccak256("midas.referrers.pendle")
    function PENDLE_REFERRER_ID() public pure virtual returns (bytes32) {
        return 0xeebc7fb7758166393aa5eeda20861581606265fd83e1f138b4d07d0a78a0f769;
    }

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == yieldToken) {
            return amountDeposited;
        }

        uint256 balanceBefore = _selfBalance(yieldToken);
        _safeApproveInf(tokenIn, depositVault);
        IMidasDepositVault(depositVault).depositInstant(
            tokenIn,
            MidasAdapterLib.tokenAmountToBase18(tokenIn, amountDeposited),
            0,
            PENDLE_REFERRER_ID()
        );
        return _selfBalance(yieldToken) - balanceBefore;
    }

    function _redeem(
        address receiver,
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal override returns (uint256 amountTokenOut) {
        if (tokenOut == yieldToken) {
            _transferOut(tokenOut, receiver, amountSharesToRedeem);
            return amountSharesToRedeem;
        }

        uint256 balanceBefore = _selfBalance(tokenOut);
        IMidasRedemptionVault(redemptionVault).redeemInstant(tokenOut, amountSharesToRedeem, 0);
        amountTokenOut = _selfBalance(tokenOut) - balanceBefore;
        _transferOut(tokenOut, receiver, amountTokenOut);
    }

    function exchangeRate() public view virtual override returns (uint256) {
        return (IMidasDataFeed(mTokenDataFeed).getDataInBase18() * underlyingUnit) / yieldTokenUnit;
    }

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == yieldToken) {
            return amountTokenToDeposit;
        }

        // amountTokenToDeposit is converted to base 18 inside lib
        return MidasAdapterLib.estimateAmountOutDeposit(depositVault, mTokenDataFeed, tokenIn, amountTokenToDeposit);
    }

    function _previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal view override returns (uint256 /*amountTokenOut*/) {
        if (tokenOut == yieldToken) {
            return amountSharesToRedeem;
        }

        // amountTokenOut is converted back to original decimals inside lib
        return MidasAdapterLib.estimateAmountOutRedeem(redemptionVault, mTokenDataFeed, tokenOut, amountSharesToRedeem);
    }

    function getTokensIn() public view virtual override returns (address[] memory res) {
        return ArrayLib.append(IMidasManageableVault(depositVault).getPaymentTokens(), yieldToken);
    }

    function getTokensOut() public view virtual override returns (address[] memory res) {
        return ArrayLib.append(IMidasManageableVault(redemptionVault).getPaymentTokens(), yieldToken);
    }

    function isValidTokenIn(address token) public view virtual override returns (bool) {
        return token == yieldToken || IMidasManageableVault(depositVault).tokensConfig(token).dataFeed != address(0);
    }

    function isValidTokenOut(address token) public view virtual override returns (bool) {
        return token == yieldToken || IMidasManageableVault(redemptionVault).tokensConfig(token).dataFeed != address(0);
    }

    function assetInfo() external view returns (AssetType assetType, address assetAddress, uint8 assetDecimals) {
        return (AssetType.TOKEN, underlying, MidasAdapterLib.getTokenDecimals(underlying));
    }
}
