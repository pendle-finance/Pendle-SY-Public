// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../../../../interfaces/Sigma/ISigmaSP.sol";
import "../../../../interfaces/Sigma/ICurveStableSwapNG.sol";
import "../../../../interfaces/IStandardizedYieldAdapter.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SigmaSPAdapter is IStandardizedYieldAdapter {
    using SafeERC20 for IERC20;

    address public constant SP = 0x2b9C1F069Ddcd873275B3363986081bDA94A3aA3;
    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public constant BNBUSD = 0x5519a479Da8Ce3Af7f373c16f14870BbeaFDa265;
    address public constant CURVE_POOL = 0xe5F111F2594749c1Dd4815Ef512230BF9b240CBd;
    uint16 public constant CURVE_POOL_EXCHANGE_SLIPPAGE = 10; // 0.1%
    uint16 public constant SLIPPAGE_PRESISION = 1e4; // 1e4 = 100%

    address public constant PIVOT_TOKEN = SP;

    function convertToDeposit(address tokenIn, uint256 amountTokenIn) external override returns (uint256 amountOut) {
        _validAdapterTokenIn(tokenIn);
        IERC20(tokenIn).forceApprove(SP, amountTokenIn);
        amountOut = ISigmaSP(SP).deposit(msg.sender, tokenIn, amountTokenIn, 0);
    }

    function convertToRedeem(address tokenOut, uint256 amountPivotToken) external override returns (uint256 amountOut) {
        _validAdapterTokenOut(tokenOut);

        uint256 minOut = (amountPivotToken * (SLIPPAGE_PRESISION - CURVE_POOL_EXCHANGE_SLIPPAGE)) / SLIPPAGE_PRESISION;
        IERC20(SP).forceApprove(CURVE_POOL, amountPivotToken);
        amountOut = ICurveStableSwapNG(CURVE_POOL).exchange(1, 0, amountPivotToken, minOut, msg.sender);
    }

    function previewConvertToDeposit(
        address tokenIn,
        uint256 amountTokenIn
    ) external view override returns (uint256 amountOut) {
        _validAdapterTokenIn(tokenIn);

        amountOut = ISigmaSP(SP).previewDeposit(tokenIn, amountTokenIn);
    }

    function previewConvertToRedeem(
        address tokenOut,
        uint256 amountPivotToken
    ) external view override returns (uint256 amountOut) {
        _validAdapterTokenOut(tokenOut);

        amountOut = ICurveStableSwapNG(SP).get_dy(1, 0, amountPivotToken);
    }

    function getAdapterTokensDeposit() external pure override returns (address[] memory tokens) {
        tokens = new address[](2);
        tokens[0] = USDT;
        tokens[1] = BNBUSD;
    }

    function getAdapterTokensRedeem() external pure override returns (address[] memory tokens) {
        tokens = new address[](1);
        tokens[0] = USDT;
    }

    function _validAdapterTokenIn(address tokenIn) internal pure {
        require(tokenIn == USDT || tokenIn == BNBUSD, "Adapter: Invalid token");
    }

    function _validAdapterTokenOut(address tokenOut) internal pure {
        require(tokenOut == USDT, "Adapter: Invalid token");
    }
}
