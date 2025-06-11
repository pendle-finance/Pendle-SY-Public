// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../../../libraries/ArrayLib.sol";
import "../../../../interfaces/IStandardizedYieldAdapter.sol";
import "../../../../interfaces/InfiniFi/InfiniFiInterfaces.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract PendleInfiniFiAdapter is IStandardizedYieldAdapter {
    using SafeERC20 for IERC20;

    error TokenMustBeUSDC(address token);

    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant IUSD = 0x48f9e38f3070AD8945DFEae3FA70987722E3D89c;
    address public constant GATEWAY_PROXY = 0x3f04b65Ddbd87f9CE0A2e7Eb24d80e7fb87625b5;

    address public constant PIVOT_TOKEN = IUSD;

    constructor() {
        IERC20(IUSD).forceApprove(GATEWAY_PROXY, type(uint256).max);
        IERC20(USDC).forceApprove(GATEWAY_PROXY, type(uint256).max);
    }

    modifier onlyUSDC(address _token) {
        if (_token != USDC) {
            revert TokenMustBeUSDC(_token);
        }
        _;
    }

    function convertToDeposit(
        address tokenIn,
        uint256 amountTokenIn
    ) external override onlyUSDC(tokenIn) returns (uint256) {
        return InfiniFiGateway(GATEWAY_PROXY).mint(msg.sender, amountTokenIn);
    }

    function convertToRedeem(
        address tokenOut,
        uint256 amountYieldTokenIn
    ) external override onlyUSDC(tokenOut) returns (uint256) {
        uint256 assetAmountOut = _receiptToAsset(amountYieldTokenIn);
        return InfiniFiGateway(GATEWAY_PROXY).redeem(msg.sender, amountYieldTokenIn, assetAmountOut);
    }

    function previewConvertToDeposit(
        address tokenIn,
        uint256 amountTokenIn
    ) external view override onlyUSDC(tokenIn) returns (uint256 /*amountOut*/) {
        return _assetToReceipt(amountTokenIn);
    }

    function previewConvertToRedeem(
        address tokenOut,
        uint256 amountYieldTokenIn
    ) external view override onlyUSDC(tokenOut) returns (uint256 /*amountOut*/) {
        return _receiptToAsset(amountYieldTokenIn);
    }

    function getAdapterTokensDeposit() external pure override returns (address[] memory) {
        return ArrayLib.create(USDC);
    }

    function getAdapterTokensRedeem() external pure override returns (address[] memory) {
        return ArrayLib.create(USDC);
    }

    function _receiptToAsset(uint256 amountReceipt) internal view returns (uint256) {
        address redeemController = InfiniFiGateway(GATEWAY_PROXY).getAddress("redeemController");
        return IRedeemController(redeemController).receiptToAsset(amountReceipt);
    }

    function _assetToReceipt(uint256 amountAsset) internal view returns (uint256) {
        address mintController = InfiniFiGateway(GATEWAY_PROXY).getAddress("mintController");
        return IMintController(mintController).assetToReceipt(amountAsset);
    }
}
