// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../../../../interfaces/Cap/ICUSD.sol";
import "../../../../interfaces/IStandardizedYieldAdapter.sol";
import "../../../libraries/TokenHelper.sol";

contract PendleCUSDAdapter is IStandardizedYieldAdapter, TokenHelper {
    address public constant cUSD = 0xcCcc62962d17b8914c62D74FfB843d73B2a3cccC;
    address public constant PIVOT_TOKEN = cUSD;

    uint256 internal constant MAX_DEADLINE = type(uint256).max;

    function convertToDeposit(address tokenIn, uint256 amountTokenIn) external returns (uint256 amountOut) {
        _safeApproveInf(tokenIn, cUSD);
        return ICUSD(cUSD).mint(tokenIn, amountTokenIn, 0, msg.sender, MAX_DEADLINE);
    }

    function convertToRedeem(address tokenOut, uint256 amountPivotTokenIn) external returns (uint256 amountOut) {
        return ICUSD(cUSD).burn(tokenOut, amountPivotTokenIn, 0, msg.sender, MAX_DEADLINE);
    }

    function previewConvertToDeposit(address tokenIn, uint256 amountTokenIn)
        external
        view
        returns (uint256 amountOut)
    {
        (amountOut,) = ICUSD(cUSD).getMintAmount(tokenIn, amountTokenIn);
    }

    function previewConvertToRedeem(address tokenOut, uint256 amountPivotTokenIn)
        external
        view
        returns (uint256 amountOut)
    {
        (amountOut,) = ICUSD(cUSD).getBurnAmount(tokenOut, amountPivotTokenIn);
    }

    function getAdapterTokensDeposit() external view returns (address[] memory tokens) {
        address[] memory allAssets = ICUSD(cUSD).assets();
        tokens = new address[](allAssets.length);

        uint256 supportedAssetsLength;

        for (uint256 i = 0; i < allAssets.length;) {
            if (!ICUSD(cUSD).paused(allAssets[i])) {
                tokens[supportedAssetsLength++] = allAssets[i];
            }

            unchecked {
                ++i;
            }
        }

        assembly {
            mstore(tokens, supportedAssetsLength)
        }
    }

    function getAdapterTokensRedeem() external view returns (address[] memory tokens) {
        return ICUSD(cUSD).assets();
    }
}
