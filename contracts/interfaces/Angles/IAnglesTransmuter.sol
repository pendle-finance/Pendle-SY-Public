// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IAnglesTransmuter {
    function swapExactInput(
        uint256 amountIn,
        uint256 amountOutMin,
        address tokenIn,
        address tokenOut,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function quoteIn(uint256 amountIn, address tokenIn, address tokenOut) external view returns (uint256 amountOut);
}
