// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../../../libraries/TokenHelper.sol";
import "../../../../interfaces/IStandardizedYieldAdapter.sol";
import "../../../../interfaces/GAIB/IStablecoinMinter.sol";

contract PendleAIDAdapter is IStandardizedYieldAdapter, TokenHelper {
    address public immutable aid;
    address public immutable stablecoin;
    address public immutable aidStablecoinMinter;

    uint256 public immutable DECIMAL_ADJUSTMENT;

    constructor(address _aidStablecoinMinter) {
        aidStablecoinMinter = _aidStablecoinMinter;
        aid = IStablecoinMinter(aidStablecoinMinter).aid();
        stablecoin = IStablecoinMinter(aidStablecoinMinter).stablecoin();
        DECIMAL_ADJUSTMENT = IStablecoinMinter(aidStablecoinMinter).DECIMAL_ADJUSTMENT();

        _safeApproveInf(stablecoin, aidStablecoinMinter);
    }

    function PIVOT_TOKEN() external view returns (address pivotToken) {
        return aid;
    }

    function convertToDeposit(address /*tokenIn*/, uint256 amountTokenIn) external returns (uint256 amountOut) {
        amountOut = IStablecoinMinter(aidStablecoinMinter).mint(amountTokenIn);
        _transferOut(aid, msg.sender, amountOut);
    }

    function previewConvertToDeposit(
        address /*tokenIn*/,
        uint256 amountTokenIn
    ) external view returns (uint256 amountOut) {
        return amountTokenIn * DECIMAL_ADJUSTMENT;
    }

    function getAdapterTokensDeposit() external view returns (address[] memory tokens) {
        tokens = new address[](1);
        tokens[0] = stablecoin;
    }

    function convertToRedeem(
        address /*tokenOut*/,
        uint256 /*amountPivotTokenIn*/
    ) external returns (uint256 /*amountOut*/) {}

    function previewConvertToRedeem(
        address /*tokenOut*/,
        uint256 /*amountPivotTokenIn*/
    ) external view returns (uint256 /*amountOut*/) {}

    function getAdapterTokensRedeem() external pure returns (address[] memory tokens) {
        tokens = new address[](0);
    }
}
