// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../PendleERC4626UpgSYV2.sol";
import "../../../../interfaces/FX/IFXBase.sol";
import "./PendleFxCurvePoolHelper.sol";

interface IFxUSDBasePool {
    function instantRedeem(
        address receiver,
        uint256 amountSharesToRedeem
    ) external returns (uint256 amountYieldOut, uint256 amountStableOut);

    function instantRedeemFeeRatio() external view returns (uint256);

    function previewRedeem(
        uint256 amountSharesToRedeem
    ) external view returns (uint256 amountYieldOut, uint256 amountStableOut);
}

contract PendleFXSaveSY is PendleERC4626UpgSYV2, PendleFxCurvePoolHelper {
    using PMath for uint256;

    address public constant FXSAVE = 0x7743e50F534a7f9F1791DdE7dCD89F7783Eefc39;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant FXUSD = 0x085780639CC2cACd35E474e71f4d000e2405d8f6;

    constructor() PendleERC4626UpgSYV2(FXSAVE) {}

    function initialize() external virtual initializer {
        __SYBaseUpg_init("SY f(x) USD Saving", "SY-fxSAVE");
        _safeApproveInf(asset, yieldToken);
        _safeApproveInf(USDC, asset);
        _safeApproveInf(FXUSD, asset);
    }

    function approveForCurvePool() external virtual {
        _approveForCurvePool();
    }

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == USDC || tokenIn == FXUSD) {
            (tokenIn, amountDeposited) = (asset, IFXBase(asset).deposit(address(this), tokenIn, amountDeposited, 0));
        }
        return super._deposit(tokenIn, amountDeposited);
    }

    function _redeem(
        address receiver,
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal virtual override returns (uint256) {
        if (tokenOut == yieldToken || tokenOut == asset) {
            return super._redeem(receiver, tokenOut, amountSharesToRedeem);
        } else {
            // tokenOut is either USDC or FXUSD
            uint256 amountAssetOut = IERC4626(yieldToken).redeem(amountSharesToRedeem, address(this), address(this));
            (uint256 amtFxUSD, uint256 amtUSDC) = IFxUSDBasePool(asset).instantRedeem(address(this), amountAssetOut);

            uint256 amountToSwap = tokenOut == USDC ? amtFxUSD : amtUSDC;
            uint256 amountOut = tokenOut == USDC ? amtUSDC : amtFxUSD;

            amountOut += _swap(tokenOut, amountToSwap);
            _transferOut(tokenOut, receiver, amountOut);
            return amountOut;
        }
    }

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == USDC || tokenIn == FXUSD) {
            (tokenIn, amountTokenToDeposit) = (asset, IFXBase(asset).previewDeposit(tokenIn, amountTokenToDeposit));
        }
        return super._previewDeposit(tokenIn, amountTokenToDeposit);
    }

    function _previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal view virtual override returns (uint256 /*amountTokenOut*/) {
        if (tokenOut == yieldToken || tokenOut == asset) {
            return super._previewRedeem(tokenOut, amountSharesToRedeem);
        } else {
            // tokenOut is either USDC or FXUSD
            uint256 amountAssetOut = IERC4626(yieldToken).previewRedeem(amountSharesToRedeem);

            (uint256 amtFxUSD, uint256 amtUSDC) = IFxUSDBasePool(asset).previewRedeem(amountAssetOut);
            uint256 fee = IFxUSDBasePool(asset).instantRedeemFeeRatio();

            amtFxUSD -= amtFxUSD.mulDown(fee);
            amtUSDC -= amtUSDC.mulDown(fee);

            uint256 amountToSwap = tokenOut == USDC ? amtFxUSD : amtUSDC;
            uint256 amountOut = tokenOut == USDC ? amtUSDC : amtFxUSD;
            amountOut += _previewSwap(tokenOut, amountToSwap);
            return amountOut;
        }
    }

    function getTokensOut() public view virtual override returns (address[] memory res) {
        return ArrayLib.create(yieldToken, asset, USDC, FXUSD);
    }

    function isValidTokenOut(address token) public view virtual override returns (bool) {
        return token == yieldToken || token == asset || token == USDC || token == FXUSD;
    }

    function getTokensIn() public view virtual override returns (address[] memory res) {
        return ArrayLib.create(asset, yieldToken, USDC, FXUSD);
    }

    function isValidTokenIn(address token) public view virtual override returns (bool) {
        return token == USDC || token == FXUSD || token == yieldToken || token == asset;
    }
}
