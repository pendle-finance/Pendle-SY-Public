// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../PendleERC4626NoRedeemUpgSY.sol";

contract PendleLytPoolSY is PendleERC4626NoRedeemUpgSY {
    constructor(address _lytPool) PendleERC4626NoRedeemUpgSY(_lytPool) {}

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == yieldToken) return amountTokenToDeposit;
        else return IERC4626(yieldToken).convertToShares(amountTokenToDeposit);
    }
}
