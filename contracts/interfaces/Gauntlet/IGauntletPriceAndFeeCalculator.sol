// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGauntletPriceAndFeeCalculator {
    function convertUnitsToTokenIfActive(address vault, address token, uint256 unitsAmount, uint8 rounding)
        external
        view
        returns (uint256 tokenAmount);
}