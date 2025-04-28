// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;
import "../../../../../interfaces/IStandardizedYieldAdapter.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../../../../interfaces/Reservoir/IReservoirCreditEnforcer.sol";
import "../../../../../interfaces/Reservoir/IReservoirPSM.sol";

contract PendleReservoirAdapter is IStandardizedYieldAdapter {
    using SafeERC20 for IERC20;

    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant RUSD = 0x09D4214C03D01F49544C0448DBE3A27f768F2b34;

    address public constant PSM = 0x4809010926aec940b550D34a46A52739f996D75D;
    address public constant CREDIT_ENFORSER = 0x04716DB62C085D9e08050fcF6F7D775A03d07720;

    address public constant PIVOT_TOKEN = RUSD;

    uint256 public constant DECIMAL_FACTOR = 10 ** 12;

    constructor() {
        IERC20(USDC).forceApprove(PSM, type(uint256).max);
        IERC20(RUSD).forceApprove(PSM, type(uint256).max);
    }

    function convertToDeposit(
        address /*tokenIn*/,
        uint256 amountTokenIn
    ) external override returns (uint256 amountOut) {
        // assert(tokenIn == USDC);
        amountOut = IReservoirCreditEnforcer(CREDIT_ENFORSER).mintStablecoin(amountTokenIn) * DECIMAL_FACTOR;
        IERC20(RUSD).safeTransfer(msg.sender, amountOut);
    }

    function convertToRedeem(
        address /*tokenOut*/,
        uint256 amountYieldTokenIn
    ) external override returns (uint256 amountOut) {
        // assert(tokenOut == USDC);
        amountOut = amountYieldTokenIn / DECIMAL_FACTOR;
        IReservoirPSM(PSM).redeem(msg.sender, amountOut);
    }

    function previewConvertToDeposit(
        address /*tokenIn*/,
        uint256 amountIn
    ) external pure override returns (uint256 /*amountOut*/) {
        // assert(tokenIn == USDC);
        return amountIn * DECIMAL_FACTOR;
    }

    function previewConvertToRedeem(
        address /*tokenOut*/,
        uint256 amountOut
    ) external pure override returns (uint256 /*amountIn*/) {
        // assert(tokenOut == USDC);
        return amountOut / DECIMAL_FACTOR;
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
