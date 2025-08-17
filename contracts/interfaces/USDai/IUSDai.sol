// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title USDai Interface
 * @author MetaStreet Foundation
 */
interface IUSDai is IERC20 {
    /*------------------------------------------------------------------------*/
    /* Errors */
    /*------------------------------------------------------------------------*/

    /**
     * @notice Invalid address
     */
    error InvalidAddress();

    /**
     * @notice Invalid amount
     */
    error InvalidAmount();

    /*------------------------------------------------------------------------*/
    /* Events */
    /*------------------------------------------------------------------------*/

    /**
     * @notice Deposited event
     * @param caller Caller
     * @param recipient Recipient
     * @param depositToken Deposit token
     * @param depositAmount Deposit amount
     * @param mintAmount Mint amount
     */
    event Deposited(
        address indexed caller,
        address indexed recipient,
        address depositToken,
        uint256 depositAmount,
        uint256 mintAmount
    );

    /**
     * @notice Withdrawn event
     * @param caller Caller
     * @param recipient Recipient
     * @param withdrawToken Withdraw token
     * @param baseTokenAmount Base token amount
     * @param withdrawAmount Withdraw amount
     */
    event Withdrawn(
        address indexed caller,
        address indexed recipient,
        address withdrawToken,
        uint256 baseTokenAmount,
        uint256 withdrawAmount
    );

    /*------------------------------------------------------------------------*/
    /* Getters */
    /*------------------------------------------------------------------------*/

    /**
     * @notice Get swap adapter
     * @return Swap adapter
     */
    function swapAdapter() external view returns (address);

    /**
     * @notice Get base token
     * @return Base token
     */
    function baseToken() external view returns (address);

    /*------------------------------------------------------------------------*/
    /* Public API */
    /*------------------------------------------------------------------------*/

    /**
     * @notice Deposit
     * @param depositToken Deposit token
     * @param depositAmount Deposit amount
     * @param usdaiAmountMinimum Minimum USDai amount
     * @param recipient Recipient
     * @return USDai amount
     */
    function deposit(address depositToken, uint256 depositAmount, uint256 usdaiAmountMinimum, address recipient)
        external
        returns (uint256);

    /**
     * @notice Deposit
     * @param depositToken Deposit token
     * @param depositAmount Deposit amount
     * @param usdaiAmountMinimum Minimum USDai amount
     * @param recipient Recipient
     * @param data Data (for swap adapter)
     * @return USDai amount
     */
    function deposit(
        address depositToken,
        uint256 depositAmount,
        uint256 usdaiAmountMinimum,
        address recipient,
        bytes calldata data
    ) external returns (uint256);

    /**
     * @notice Withdraw
     * @param withdrawToken Withdraw token
     * @param usdaiAmount USDai amount
     * @param withdrawAmountMinimum Minimum withdraw amount
     * @param recipient Recipient
     * @return Withdraw amount
     */
    function withdraw(address withdrawToken, uint256 usdaiAmount, uint256 withdrawAmountMinimum, address recipient)
        external
        returns (uint256);

    /**
     * @notice Withdraw
     * @param withdrawToken Withdraw token
     * @param usdaiAmount USD amount
     * @param withdrawAmountMinimum Withdraw amount minimum
     * @param recipient Recipient
     * @param data Data (for swap adapter)
     * @return Withdraw amount
     */
    function withdraw(
        address withdrawToken,
        uint256 usdaiAmount,
        uint256 withdrawAmountMinimum,
        address recipient,
        bytes calldata data
    ) external returns (uint256);
}
