// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../PendleERC4626UpgSYV2.sol";
import "../../../../interfaces/Angles/IAnglesTransmuter.sol";

contract PendleStUSRSY is PendleERC4626UpgSYV2 {
    using SafeERC20 for IERC20;

    address public constant EURC = 0x1aBaEA1f7C830bD89Acc67eC4af516284b1bC33c;
    address public constant STEUR = 0x004626A008B1aCdC4c74ab51644093b155e59A23;
    address public constant TRANSMUTER = 0x00253582b2a3FE112feEC532221d9708c64cEFAb;

    constructor() PendleERC4626UpgSYV2(STEUR) {}

    function initialize() external initializer {
        __SYBaseUpg_init("SY Staked EURA", "SY-stEUR");
        _safeApproveInf(EURC, TRANSMUTER);
        _safeApproveInf(asset, TRANSMUTER);
        _safeApproveInf(asset, yieldToken);
    }

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == EURC) {
            (tokenIn, amountDeposited) = (
                asset,
                IAnglesTransmuter(TRANSMUTER).swapExactInput(
                    amountDeposited,
                    0,
                    tokenIn,
                    asset,
                    address(this),
                    type(uint256).max
                )
            );
        }
        return super._deposit(tokenIn, amountDeposited);
    }

    function _redeem(
        address receiver,
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal virtual override returns (uint256) {
        if (tokenOut == yieldToken) {
            _transferOut(yieldToken, receiver, amountSharesToRedeem);
            return amountSharesToRedeem;
        } else {
            if (tokenOut == asset) {
                return IERC4626(yieldToken).redeem(amountSharesToRedeem, receiver, address(this));
            } else {
                uint256 amountAssetOut = IERC4626(yieldToken).redeem(
                    amountSharesToRedeem,
                    address(this),
                    address(this)
                );
                return
                    IAnglesTransmuter(TRANSMUTER).swapExactInput(
                        amountAssetOut,
                        0,
                        asset,
                        tokenOut,
                        receiver,
                        type(uint256).max
                    );
            }
        }
    }

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == EURC) {
            (tokenIn, amountTokenToDeposit) = (
                asset,
                IAnglesTransmuter(TRANSMUTER).quoteIn(amountTokenToDeposit, tokenIn, asset)
            );
        }
        return super._previewDeposit(tokenIn, amountTokenToDeposit);
    }

    function _previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal view virtual override returns (uint256 /*amountTokenOut*/) {
        if (tokenOut == yieldToken) return amountSharesToRedeem;

        uint256 amountAssetOut = IERC4626(yieldToken).previewRedeem(amountSharesToRedeem);
        if (tokenOut == asset) {
            return amountAssetOut;
        } else {
            return IAnglesTransmuter(TRANSMUTER).quoteIn(amountAssetOut, asset, tokenOut);
        }
    }

    function getTokensIn() public view virtual override returns (address[] memory res) {
        return ArrayLib.create(EURC, asset, yieldToken);
    }

    function getTokensOut() public view virtual override returns (address[] memory res) {
        return ArrayLib.create(EURC, asset, yieldToken);
    }

    function isValidTokenIn(address token) public view virtual override returns (bool) {
        return token == EURC || token == asset || token == yieldToken;
    }

    function isValidTokenOut(address token) public view virtual override returns (bool) {
        return token == EURC || token == asset || token == yieldToken;
    }
}
