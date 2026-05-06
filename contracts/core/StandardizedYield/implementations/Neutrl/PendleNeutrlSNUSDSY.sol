// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Adapter/extensions/supplyCap/PendleERC4626WithAdapterAndSupplyCapSY.sol";
import "../../../../interfaces/Neutrl/IInstantUnstaking.sol";

contract PendleNeutrlSNUSDSY is PendleERC4626WithAdapterAndSupplyCapSY {
    address public immutable instantUnstaking;

    constructor(
        address _erc4626,
        address _instantUnstaking,
        address _offchainRewardManager
    ) PendleERC4626WithAdapterAndSupplyCapSY(_erc4626, _offchainRewardManager) {
        instantUnstaking = _instantUnstaking;
    }

    function _redeem(
        address receiver,
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal virtual override returns (uint256) {
        if (tokenOut == yieldToken) {
            _transferOut(yieldToken, receiver, amountSharesToRedeem);
            return amountSharesToRedeem;
        } else {
            _safeApprove(yieldToken, instantUnstaking, amountSharesToRedeem);
            uint256 amountTokenOut = IInstantUnstaking(instantUnstaking).instantUnstake(amountSharesToRedeem, 0);
            _transferOut(tokenOut, receiver, amountTokenOut);
            return amountTokenOut;
        }
    }

    function _previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal view virtual override returns (uint256) {
        if (tokenOut == yieldToken) {
            return amountSharesToRedeem;
        } else {
            (uint256 amountTokenOut, ) = IInstantUnstaking(instantUnstaking).quoteInstantUnstake(
                address(this),
                amountSharesToRedeem
            );
            return amountTokenOut;
        }
    }
}
