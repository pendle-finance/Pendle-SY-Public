// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../PendleERC20SYUpgV2.sol";
import {AggregatorV2V3Interface as IChainlinkAggregator} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

contract PendleSyrupArbitrumSY is PendleERC20SYUpgV2 {
    using PMath for uint256;
    using PMath for int256;

    address public immutable chainlinkFeed;
    address internal immutable underlyingAssetAddr;
    uint8 internal immutable underlyingAssetDecimals;

    constructor(
        address _yieldToken,
        address _chainlinkFeed,
        address _underlyingAssetAddr,
        uint8 _underlyingAssetDecimals
    ) PendleERC20SYUpgV2(_yieldToken) {
        chainlinkFeed = _chainlinkFeed;
        underlyingAssetAddr = _underlyingAssetAddr;
        underlyingAssetDecimals = _underlyingAssetDecimals;
    }

    function exchangeRate() public view override returns (uint256 res) {
        uint8 oracleDecimals = IChainlinkAggregator(chainlinkFeed).decimals();
        (, int256 latestAnswer, , , ) = IChainlinkAggregator(chainlinkFeed).latestRoundData();
        return latestAnswer.Uint().divDown(10 ** oracleDecimals);
    }

    function assetInfo()
        external
        view
        override
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.TOKEN, underlyingAssetAddr, underlyingAssetDecimals);
    }
}
