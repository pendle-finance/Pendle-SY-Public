// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../../../interfaces/Sky/ISkyConverter.sol";
import "../../../interfaces/IStandardizedYieldAdapter.sol";
import "../../../interfaces/IERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract PendleERC4626Adapter is IStandardizedYieldAdapter {
    using SafeERC20 for IERC20;

    address public immutable asset;
    address public immutable erc4626;
    address public immutable PIVOT_TOKEN;

    constructor(address _erc4626) {
        erc4626 = _erc4626;
        PIVOT_TOKEN = _erc4626;
        asset = IERC4626(_erc4626).asset();
    }

    function convertToDeposit(address /*tokenIn*/, uint256 amountTokenIn) external override returns (uint256) {
        // assert(tokenIn == asset);
        return IERC4626(erc4626).deposit(amountTokenIn, msg.sender);
    }

    function convertToRedeem(address /*tokenOut*/, uint256 amountPivotTokenIn) external override returns (uint256) {
        // assert(tokenOut == asset);
        return IERC4626(erc4626).redeem(amountPivotTokenIn, msg.sender, address(this));
    }

    function previewConvertToDeposit(
        address /*tokenIn*/,
        uint256 amountTokenIn
    ) external view override returns (uint256 amountOut) {
        // assert(tokenIn == asset);
        return IERC4626(erc4626).previewDeposit(amountTokenIn);
    }

    function previewConvertToRedeem(
        address /*tokenOut*/,
        uint256 amountPivotTokenIn
    ) external view override returns (uint256 amountOut) {
        // assert(tokenOut == asset);
        return IERC4626(erc4626).previewRedeem(amountPivotTokenIn);
    }

    function getAdapterTokensDeposit() external view override returns (address[] memory tokens) {
        tokens = new address[](1);
        tokens[0] = asset;
    }

    function getAdapterTokensRedeem() external view override returns (address[] memory tokens) {
        tokens = new address[](1);
        tokens[0] = asset;
    }
}
