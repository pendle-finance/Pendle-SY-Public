// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.28;

import "./PendleCommonSYWithAdapterUpg.sol";
import "../../../../interfaces/IERC4626.sol";
import "../../../libraries/DecimalsWrapperLib.sol";

contract PendleCommonERC4626SYUpg is PendleCommonSYWithAdapterUpg {
    using ArrayLib for address[];

    address public immutable erc4626;
    address public immutable asset;
    address public immutable assetScaled18;
    bool public immutable canDepositAsset;
    bool public immutable canRedeemAsset;
    uint256 internal immutable scale;
    uint256 internal immutable exchangeRateUnit;

    uint256[100] private __gap;

    constructor(
        address _erc4626,
        bool _canDepositAsset,
        bool _canRedeemAsset,
        address _decimalsWrapperFactory,
        address _offchainRewardManager
    )
        PendleCommonSYWithAdapterUpg(
            DecimalsWrapperLib.scaled18(_decimalsWrapperFactory, _erc4626),
            IERC4626(_erc4626).asset(),
            _offchainRewardManager
        )
    {
        erc4626 = _erc4626;
        asset = pivotToken;
        assetScaled18 = DecimalsWrapperLib.scaled18(_decimalsWrapperFactory, pivotToken);
        canDepositAsset = _canDepositAsset;
        canRedeemAsset = _canRedeemAsset;
        scale = DecimalsWrapperLib.scale18(_erc4626);
        exchangeRateUnit = (PMath.ONE / scale) * DecimalsWrapperLib.scale18(pivotToken);
    }

    function _afterInitialize() internal override {
        _safeApproveInf(asset, erc4626);
    }

    /*///////////////////////////////////////////////////////////////
                    DEPOSIT/REDEEM USING BASE TOKENS
    //////////////////////////////////////////////////////////////*/

    function _deposit(address tokenIn, uint256 amountIn) internal override returns (uint256 amountSharesOut) {
        if (tokenIn != erc4626) {
            if (tokenIn != asset) amountIn = _adapterDeposit(tokenIn, amountIn);
            amountIn = IERC4626(erc4626).deposit(amountIn, address(this));
        }
        amountSharesOut = amountIn * scale;
        require(_selfBalance(erc4626) * scale >= totalSupply() + amountSharesOut, "SY: insufficient shares");
    }

    function _redeem(
        address receiver,
        address tokenOut,
        uint256 amountShares
    ) internal override returns (uint256 amountOut) {
        amountOut = amountShares / scale;
        if (tokenOut == erc4626) {
            _transferOut(erc4626, receiver, amountOut);
        } else if (tokenOut == asset) {
            amountOut = IERC4626(erc4626).redeem(amountOut, receiver, address(this));
        } else {
            address _adapter = adapter;
            amountOut = IERC4626(erc4626).redeem(amountOut, _adapter, address(this));
            amountOut = IStandardizedYieldAdapter(_adapter).convertToRedeem(tokenOut, amountOut);
            _transferOut(tokenOut, receiver, amountOut);
        }
    }

    function _previewDeposit(address tokenIn, uint256 amountIn) internal view override returns (uint256) {
        if (tokenIn != erc4626) {
            if (tokenIn != asset) {
                amountIn = IStandardizedYieldAdapter(adapter).previewConvertToDeposit(tokenIn, amountIn);
            }
            amountIn = IERC4626(erc4626).previewDeposit(amountIn);
        }
        return amountIn * scale;
    }

    function _previewRedeem(address tokenOut, uint256 amountShares) internal view override returns (uint256 amountOut) {
        amountOut = amountShares / scale;
        if (tokenOut != erc4626) {
            amountOut = IERC4626(erc4626).previewRedeem(amountOut);
            if (tokenOut != asset) {
                amountOut = IStandardizedYieldAdapter(adapter).previewConvertToRedeem(tokenOut, amountOut);
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                               EXCHANGE-RATE
    //////////////////////////////////////////////////////////////*/

    function exchangeRate() public view override returns (uint256) {
        return IERC4626(erc4626).convertToAssets(exchangeRateUnit);
    }

    /*///////////////////////////////////////////////////////////////
                        MISC FUNCTIONS FOR METADATA
    //////////////////////////////////////////////////////////////*/

    function getTokensIn() public view override returns (address[] memory) {
        if (!canDepositAsset) return ArrayLib.create(erc4626);
        if (adapter == address(0)) return ArrayLib.create(asset, erc4626);
        return IStandardizedYieldAdapter(adapter).getAdapterTokensDeposit().append(asset, erc4626);
    }

    function getTokensOut() public view override returns (address[] memory) {
        if (!canRedeemAsset) return ArrayLib.create(erc4626);
        if (adapter == address(0)) return ArrayLib.create(asset, erc4626);
        return IStandardizedYieldAdapter(adapter).getAdapterTokensRedeem().append(asset, erc4626);
    }

    function isValidTokenIn(address token) public view override returns (bool) {
        return token == erc4626 || (canDepositAsset && (token == asset || _isAdapterTokenIn(token)));
    }

    function isValidTokenOut(address token) public view override returns (bool) {
        return token == erc4626 || (canRedeemAsset && (token == asset || _isAdapterTokenOut(token)));
    }

    function assetInfo() external view virtual returns (AssetType, address, uint8) {
        return (AssetType.TOKEN, assetScaled18, 18);
    }

    function pricingInfo() external view override returns (address refToken, bool refStrictlyEqual) {
        return (erc4626, true);
    }
}
