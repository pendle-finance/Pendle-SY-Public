// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Adapter/extensions/PendleERC4626NoRedeemWithAdapterSY.sol";
import "../../../../interfaces/OpenEden/IXPRISM.sol";

contract PendleXPRISMSY is PendleERC4626NoRedeemWithAdapterSY {
    constructor(
        address _erc4626,
        address _offchainRewardManager
    ) PendleERC4626NoRedeemWithAdapterSY(_erc4626, _offchainRewardManager) {}

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == yieldToken) {
            return amountDeposited;
        } else {
            return IXPRISM(yieldToken).stake(amountDeposited, 0);
        }
    }
}
