// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../../../../interfaces/IStandardizedYieldAdapter.sol";
import "../../../../interfaces/InfiniFi/InfiniFiInterfaces.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract PendleEmptyAdapter is IStandardizedYieldAdapter {
    using SafeERC20 for IERC20;

    error TokenMustBeUSDC();

    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant IUSD = 0x48f9e38f3070AD8945DFEae3FA70987722E3D89c;

    address public constant PIVOT_TOKEN = IUSD;

    address public constant GATEWAY_PROXY = 0x3f04b65Ddbd87f9CE0A2e7Eb24d80e7fb87625b5;
    address public constant MINT_CONTROLLER = 0x49877d937B9a00d50557bdC3D87287b5c3a4C256;
    address public constant REDEEM_CONTROLLER = 0xCb1747E89a43DEdcF4A2b831a0D94859EFeC7601;

    constructor() {
        IERC20(IUSD).forceApprove(GATEWAY_PROXY, type(uint256).max);
        IERC20(USDC).forceApprove(GATEWAY_PROXY, type(uint256).max);
    }

    function convertToDeposit(
        address tokenIn,
        uint256 amountTokenIn
    ) external override returns (uint256 amountOut) {
        if(tokenIn != USDC) {
            revert TokenMustBeUSDC();
        }
        amountOut = InfiniFiGateway(GATEWAY_PROXY).mint(msg.sender, amountTokenIn);
    }

    function convertToRedeem(
        address tokenOut,
        uint256 amountYieldTokenIn
    ) external override returns (uint256 amountOut) {
        if(tokenOut != USDC) {
            revert TokenMustBeUSDC();
        }
        uint256 assetAmountOut = IRedeemController(REDEEM_CONTROLLER).receiptToAsset(amountYieldTokenIn);
        amountOut = InfiniFiGateway(GATEWAY_PROXY).redeem(msg.sender, amountYieldTokenIn, assetAmountOut);
    }

    function previewConvertToDeposit(
        address tokenIn,
        uint256 amountTokenIn
    ) external view override returns (uint256 /*amountOut*/) {
        if (tokenIn == USDC) {
            return IMintController(MINT_CONTROLLER).assetToReceipt(amountTokenIn);
        }
        return 0;
    }

    function previewConvertToRedeem(
        address tokenOut,
        uint256 amountYieldTokenIn
    ) external view override returns (uint256 /*amountOut*/) {
        if (tokenOut == USDC) {
            return IRedeemController(REDEEM_CONTROLLER).receiptToAsset(amountYieldTokenIn);
        }
        return 0;
    }

    function getAdapterTokensDeposit() external pure override returns (address[] memory tokens) {
        tokens = new address[](1);
        tokens[0] = USDC;
    }

    function getAdapterTokensRedeem() external pure override returns (address[] memory tokens) {
        tokens = new address[](1);
        tokens[0] = USDC;
    }
}
