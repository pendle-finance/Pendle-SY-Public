// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "./PendleERC20SYUpgV2.sol";
import {IPExchangeRateOracle} from "../../../interfaces/IPExchangeRateOracle.sol";

contract PendleERC20WithOracleSY is PendleERC20SYUpgV2 {
    address public immutable underlyingAsset;
    address public immutable exchangeRateOracle;

    constructor(
        address _yieldToken,
        address _underlyingAsset,
        address _exchangeRateOracle
    ) PendleERC20SYUpgV2(_yieldToken) {
        underlyingAsset = _underlyingAsset;
        exchangeRateOracle = _exchangeRateOracle;
    }

    function exchangeRate() public view override returns (uint256 res) {
        return IPExchangeRateOracle(exchangeRateOracle).getExchangeRate();
    }

    function assetInfo()
        external
        view
        override
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.TOKEN, underlyingAsset, IERC20Metadata(underlyingAsset).decimals());
    }
}
