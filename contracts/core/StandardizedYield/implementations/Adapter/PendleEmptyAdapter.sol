// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../../../../interfaces/IStandardizedYieldAdapter.sol";

contract PendleEmptyAdapter is IStandardizedYieldAdapter {
    function convertToDeposit(
        address /*tokenIn*/,
        uint256 /*amountTokenIn*/
    ) external pure override returns (address /*tokenOut*/, uint256 /*amountOut*/) {
        revert("Adapter: Not implemented");
    }

    function convertToRedeem(
        address /*tokenOut*/,
        uint256 /*amountYieldTokenIn*/
    ) external pure override returns (uint256 /*amountOut*/) {
        revert("Adapter: Not implemented");
    }

    function previewConvertToDeposit(
        address /*tokenIn*/,
        uint256 /*amountTokenIn*/
    ) external pure override returns (address /*tokenOut*/, uint256 /*amountOut*/) {
        revert("Adapter: Not implemented");
    }

    function previewConvertToRedeem(
        address /*tokenOut*/,
        uint256 /*amountYieldTokenIn*/
    ) external pure override returns (uint256 /*amountOut*/) {
        revert("Adapter: Not implemented");
    }

    function getAdapterTokensDeposit() external pure override returns (address[] memory tokens) {
        return new address[](0);
    }

    function getAdapterTokensRedeem() external pure override returns (address[] memory tokens) {
        return new address[](0);
    }
}
