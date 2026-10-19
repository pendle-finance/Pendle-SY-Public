// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../../../libraries/TokenHelper.sol";
import "../../../../interfaces/IStandardizedYieldAdapter.sol";
import "../../../../interfaces/Centrifuge/ICentrifugePassthroughVault.sol";

contract PendleCentrifugePassthroughAdapter is IStandardizedYieldAdapter, TokenHelper {
    address public immutable passthroughVault;
    address public immutable asset;
    address public immutable share;

    constructor(address _passthroughVault) {
        passthroughVault = _passthroughVault;
        asset = ICentrifugePassthroughVault(_passthroughVault).asset();
        share = ICentrifugePassthroughVault(_passthroughVault).share();

        _safeApproveInf(asset, _passthroughVault);
    }

    function PIVOT_TOKEN() external view returns (address pivotToken) {
        return share;
    }

    function convertToDeposit(address /*tokenIn*/, uint256 amountTokenIn) external returns (uint256 amountOut) {
        return ICentrifugePassthroughVault(passthroughVault).deposit(amountTokenIn, msg.sender);
    }

    function previewConvertToDeposit(
        address /*tokenIn*/,
        uint256 amountTokenIn
    ) external view returns (uint256 amountOut) {
        require(
            amountTokenIn <= ICentrifugePassthroughVault(passthroughVault).maxDeposit(address(this)),
            "exceeds capacity"
        );
        return ICentrifugePassthroughVault(passthroughVault).previewDeposit(amountTokenIn);
    }

    function getAdapterTokensDeposit() external view returns (address[] memory tokens) {
        tokens = new address[](1);
        tokens[0] = asset;
    }

    function convertToRedeem(
        address /*tokenOut*/,
        uint256 /*amountPivotTokenIn*/
    ) external pure returns (uint256 /*amountOut*/) {
        revert("not supported");
    }

    function previewConvertToRedeem(
        address /*tokenOut*/,
        uint256 /*amountPivotTokenIn*/
    ) external pure returns (uint256 /*amountOut*/) {
        revert("not supported");
    }

    function getAdapterTokensRedeem() external pure returns (address[] memory tokens) {
        tokens = new address[](0);
    }
}
