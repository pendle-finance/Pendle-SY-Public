// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../../v2/SYBaseUpgV2.sol";
import "../../../../interfaces/Strata/IStrataTranche.sol";
import "../../../../interfaces/Strata/IStrataCDO.sol";
import "../../../../interfaces/Strata/IStrataMidasStrategy.sol";
import "../../../../interfaces/Midas/IMidasDepositVault.sol";
import "../../../../interfaces/Midas/IMidasRedemptionVault.sol";
import "../Midas/libraries/MidasAdapterLib.sol";

contract PendleStrataMidasTrancheSY is SYBaseUpgV2 {
    address public immutable strata;
    bool public immutable isJrt;
    address public immutable asset;
    address public immutable mToken;
    address public immutable mTokenDataFeed;
    address public immutable midasDepositVault;
    address public immutable midasRedemptionVault;

    constructor(
        address _strata,
        address _mToken,
        address _mTokenDataFeed,
        address _midasDepositVault,
        address _midasRedemptionVault
    ) SYBaseUpgV2(_strata) {
        strata = _strata;
        asset = IStrataTranche(_strata).asset();
        mToken = _mToken;
        mTokenDataFeed = _mTokenDataFeed;
        midasDepositVault = _midasDepositVault;
        midasRedemptionVault = _midasRedemptionVault;

        isJrt = IStrataCDO(IStrataTranche(strata).cdo()).isJrt(strata);
    }

    function initialize(string memory name_, string memory symbol_, address _owner) external initializer {
        __SYBaseUpgV2_init(name_, symbol_, _owner);
        _safeApproveInf(mToken, midasRedemptionVault);
    }

    function exchangeRate() external view override returns (uint256) {
        return IStrataTranche(strata).convertToAssets(PMath.ONE);
    }

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 amountSharesOut) {
        if (tokenIn == strata) {
            return amountDeposited;
        }

        // Strata integrates midasDepositVault natively
        _safeApprove(tokenIn, strata, amountDeposited);
        return IStrataTranche(strata).deposit(tokenIn, amountDeposited, address(this));
    }

    function _redeem(
        address receiver,
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal override returns (uint256) {
        if (tokenOut == strata) {
            _transferOut(strata, receiver, amountSharesToRedeem);
            return amountSharesToRedeem;
        }

        // redeem to mToken first
        uint256 amountTokenOut = IStrataTranche(strata).redeem(
            mToken,
            amountSharesToRedeem,
            address(this),
            address(this)
        );

        if (tokenOut != mToken) {
            uint256 balanceBefore = _selfBalance(tokenOut);
            IMidasRedemptionVault(midasRedemptionVault).redeemInstant(tokenOut, amountTokenOut, 0);
            amountTokenOut = _selfBalance(tokenOut) - balanceBefore;
        }

        _transferOut(tokenOut, receiver, amountTokenOut);
        return amountTokenOut;
    }

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == strata) {
            return amountTokenToDeposit;
        }

        return IStrataTranche(strata).previewDeposit(tokenIn, amountTokenToDeposit);
    }

    function _previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal view virtual override returns (uint256 /*amountTokenOut*/) {
        if (tokenOut == strata) {
            return amountSharesToRedeem;
        }

        uint256 amountTokenOut = IStrataTranche(strata).previewRedeem(mToken, amountSharesToRedeem);
        if (tokenOut != mToken) {
            amountTokenOut = MidasAdapterLib.estimateAmountOutRedeem(
                midasRedemptionVault,
                mTokenDataFeed,
                tokenOut,
                amountTokenOut
            );
        }

        return amountTokenOut;
    }

    function getTokensIn() public view virtual override returns (address[] memory res) {
        return ArrayLib.append(IMidasManageableVault(midasDepositVault).getPaymentTokens(), strata, mToken);
    }

    function getTokensOut() public view virtual override returns (address[] memory res) {
        if (_isMTokenValidTokenOut()) {
            return ArrayLib.append(IMidasManageableVault(midasRedemptionVault).getPaymentTokens(), strata, mToken);
        }
        return ArrayLib.create(strata);
    }

    function isValidTokenIn(address token) public view virtual override returns (bool) {
        return
            token == strata ||
            token == mToken ||
            IMidasManageableVault(midasDepositVault).tokensConfig(token).dataFeed != address(0);
    }

    function isValidTokenOut(address token) public view virtual override returns (bool) {
        return
            token == strata ||
            (_isMTokenValidTokenOut() &&
                (token == mToken ||
                    IMidasManageableVault(midasRedemptionVault).tokensConfig(token).dataFeed != address(0)));
    }

    function assetInfo() external view returns (AssetType assetType, address assetAddress, uint8 assetDecimals) {
        return (AssetType.TOKEN, asset, IERC20Metadata(asset).decimals());
    }

    function _isMTokenValidTokenOut() internal view returns (bool) {
        address strategy = IStrataCDO(IStrataTranche(strata).cdo()).strategy();

        uint256 cooldownTime = isJrt
            ? IStrataMidasStrategy(strategy).mTokenCooldownJrt()
            : IStrataMidasStrategy(strategy).mTokenCooldownSrt();
        return cooldownTime == 0;
    }
}
