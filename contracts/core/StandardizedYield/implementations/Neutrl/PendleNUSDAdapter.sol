// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {INUSDRouter} from "../../../../interfaces/Neutrl/INUSDRouter.sol";
import {IStandardizedYieldAdapter} from "../../../../interfaces/IStandardizedYieldAdapter.sol";
import {ArrayLib} from "../../../libraries/ArrayLib.sol";
import {TokenHelper} from "../../../libraries/TokenHelper.sol";

contract PendleNUSDAdapter is IStandardizedYieldAdapter, TokenHelper {
    address public constant ROUTER = 0xa052883ebEe7354FC2Aa0f9c727E657FdeCa744a;
    address public constant NUSD = 0xE556ABa6fe6036275Ec1f87eda296BE72C811BCE;
    address public constant USDE = 0x4c9EDD5852cd905f086C759E8383e09bff1E68B3;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    bytes internal constant EMPTY_BYTES = "";

    constructor() {
        _safeApproveInf(USDE, ROUTER);
        _safeApproveInf(USDC, ROUTER);
        _safeApproveInf(USDT, ROUTER);
    }

    function PIVOT_TOKEN() external pure returns (address pivotToken) {
        return NUSD;
    }

    function convertToDeposit(address tokenIn, uint256 amountTokenIn) external returns (uint256 amountOut) {
        amountOut = INUSDRouter(ROUTER).quoteDeposit(tokenIn, amountTokenIn);
        INUSDRouter(ROUTER).mint(msg.sender, tokenIn, amountTokenIn, amountOut, EMPTY_BYTES);
    }

    function previewConvertToDeposit(address tokenIn, uint256 amountTokenIn) external view returns (uint256 amountOut) {
        amountOut = INUSDRouter(ROUTER).quoteDeposit(tokenIn, amountTokenIn);
    }

    function getAdapterTokensDeposit() external pure returns (address[] memory tokens) {
        return ArrayLib.create(USDT, USDC, USDE);
    }

    function convertToRedeem(address tokenOut, uint256 amountPivotTokenIn) external returns (uint256 amountOut) {}

    function previewConvertToRedeem(
        address tokenOut,
        uint256 amountPivotTokenIn
    ) external view returns (uint256 amountOut) {}

    function getAdapterTokensRedeem() external view returns (address[] memory tokens) {}
}
