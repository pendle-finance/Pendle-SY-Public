// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISigmaSP {
    /*************************
     * Public View Functions *
     *************************/

    /// @notice The address of yield token.
    function yieldToken() external view returns (address);

    /// @notice The address of stable token.
    function stableToken() external view returns (address);

    /// @notice The total amount of yield token managed in this contract
    function totalYieldToken() external view returns (uint256);

    /// @notice The total amount of stable token managed in this contract
    function totalStableToken() external view returns (uint256);

    /// @notice The net asset value, multiplied by 1e18.
    function nav() external view returns (uint256);

    /// @notice Return the stable token price, multiplied by 1e18.
    function getStableTokenPrice() external view returns (uint256);

    /// @notice Return the stable token price with scaling to 18 decimals, multiplied by 1e18.
    function getStableTokenPriceWithScale() external view returns (uint256);

    /// @notice Preview the result of deposit.
    /// @param tokenIn The address of input token.
    /// @param amount The amount of input tokens to deposit.
    /// @return amountSharesOut The amount of pool shares should receive.
    function previewDeposit(address tokenIn, uint256 amount) external view returns (uint256 amountSharesOut);

    /// @notice Preview the result of redeem.
    /// @param amountSharesToRedeem The amount of pool shares to redeem.
    /// @return amountYieldOut The amount of yield token should receive.
    /// @return amountStableOut The amount of stable token should receive.
    function previewRedeem(
        uint256 amountSharesToRedeem
    ) external view returns (uint256 amountYieldOut, uint256 amountStableOut);

    /****************************
     * Public Mutated Functions *
     ****************************/

    /// @notice Deposit token.
    /// @param receiver The address of pool shares recipient.
    /// @param tokenIn The address of input token.
    /// @param amountTokenToDeposit The amount of input tokens to deposit.
    /// @param minSharesOut The minimum amount of pool shares should receive.
    /// @return amountSharesOut The amount of pool shares received.
    function deposit(
        address receiver,
        address tokenIn,
        uint256 amountTokenToDeposit,
        uint256 minSharesOut
    ) external returns (uint256 amountSharesOut);

    /// @notice Request redeem.
    /// @param shares The amount of shares to request.
    function requestRedeem(uint256 shares) external;

    /// @notice Redeem pool shares.
    /// @param receiver The address of token recipient.
    /// @param shares The amount of pool shares to redeem.
    /// @return amountYieldOut The amount of yield token should received.
    /// @return amountStableOut The amount of stable token should received.
    function redeem(
        address receiver,
        uint256 shares
    ) external returns (uint256 amountYieldOut, uint256 amountStableOut);

    /// @notice Redeem pool shares instantly with withdraw fee.
    /// @param receiver The address of token recipient.
    /// @param shares The amount of pool shares to redeem.
    /// @return amountYieldOut The amount of yield token should received.
    /// @return amountStableOut The amount of stable token should received.
    function instantRedeem(
        address receiver,
        uint256 shares
    ) external returns (uint256 amountYieldOut, uint256 amountStableOut);

    /// @notice Rebalance all positions in the given tick.
    /// @param pool The address of pool to rebalance.
    /// @param tick The index of tick to rebalance.
    /// @param tokenIn The address of token to rebalance.
    /// @param maxAmount The maximum amount of input token to rebalance.
    /// @param minBaseOut The minimum amount of collateral tokens should receive.
    /// @return tokenUsed The amount of input token used to rebalance.
    /// @return baseOut The amount of collateral tokens rebalanced.
    function rebalance(
        address pool,
        int16 tick,
        address tokenIn,
        uint256 maxAmount,
        uint256 minBaseOut
    ) external returns (uint256 tokenUsed, uint256 baseOut);

    /// @notice Rebalance all possible ticks.
    /// @param pool The address of pool to rebalance.
    /// @param tokenIn The address of token to rebalance.
    /// @param maxAmount The maximum amount of input token to rebalance.
    /// @param minBaseOut The minimum amount of collateral tokens should receive.
    /// @return tokenUsed The amount of input token used to rebalance.
    /// @return baseOut The amount of collateral tokens rebalanced.
    function rebalance(
        address pool,
        address tokenIn,
        uint256 maxAmount,
        uint256 minBaseOut
    ) external returns (uint256 tokenUsed, uint256 baseOut);

    /// @notice Liquidate all possible ticks.
    /// @param pool The address of pool to rebalance.
    /// @param tokenIn The address of token to rebalance.
    /// @param maxAmount The maximum amount of input token to rebalance.
    /// @param minBaseOut The minimum amount of collateral tokens should receive.
    /// @return tokenUsed The amount of input token used to rebalance.
    /// @return baseOut The amount of collateral tokens rebalanced.
    function liquidate(
        address pool,
        address tokenIn,
        uint256 maxAmount,
        uint256 minBaseOut
    ) external returns (uint256 tokenUsed, uint256 baseOut);

    /// @notice Arbitrage between yield token and stable token.
    /// @param srcToken The address of source token.
    /// @param amountIn The amount of source token to use.
    /// @param receiver The address of bonus receiver.
    /// @param data The hook data to `onSwap`.
    /// @return amountOut The amount of target token swapped.
    /// @return bonusOut The amount of bonus token.
    function arbitrage(
        address srcToken,
        uint256 amountIn,
        address receiver,
        bytes calldata data
    ) external returns (uint256 amountOut, uint256 bonusOut);
}
