// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../../../../core/libraries/TokenHelper.sol";
import "../../../../interfaces/Curve/ICrvPool.sol";

abstract contract PendleFxCurvePoolHelper is TokenHelper {
    address public constant CURVE_POOL = 0x5018BE882DccE5E3F2f3B0913AE2096B9b3fB61f;

    address public constant COIN0 = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant COIN1 = 0x085780639CC2cACd35E474e71f4d000e2405d8f6;

    function _approveForCurvePool() internal {
        _safeApproveInf(COIN0, CURVE_POOL);
        _safeApproveInf(COIN1, CURVE_POOL);
    }

    function _swap(address toToken, uint256 amount) internal returns (uint256) {
        int128 i = toToken == COIN0 ? int128(1) : int128(0);
        int128 j = toToken == COIN0 ? int128(0) : int128(1);
        return ICrvPool(CURVE_POOL).exchange(i, j, amount, 0);
    }

    function _previewSwap(address toToken, uint256 amount) internal view returns (uint256 amountOut) {
        int128 i = toToken == COIN0 ? int128(1) : int128(0);
        int128 j = toToken == COIN0 ? int128(0) : int128(1);
        return ICrvPool(CURVE_POOL).get_dy(i, j, amount);
    }
}
