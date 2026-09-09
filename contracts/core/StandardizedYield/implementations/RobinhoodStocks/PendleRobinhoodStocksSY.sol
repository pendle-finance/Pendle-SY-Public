// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../PendleERC20SYUpgV2.sol";
import {IScaledUIAmount} from "../../../../interfaces/IScaledUIAmount.sol";

contract PendleRobinhoodStocksSY is PendleERC20SYUpgV2 {
    constructor(address _yieldToken) PendleERC20SYUpgV2(_yieldToken) {}

    function exchangeRate() public view override returns (uint256 res) {
        return IScaledUIAmount(yieldToken).uiMultiplier();
    }

    function assetInfo()
        external
        view
        override
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.LIQUIDITY, yieldToken, IERC20Metadata(yieldToken).decimals());
    }
}
