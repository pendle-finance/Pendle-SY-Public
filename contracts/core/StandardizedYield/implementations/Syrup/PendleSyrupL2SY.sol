// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../PendleERC20SYUpgV2.sol";
import {AggregatorV2V3Interface as IChainlinkAggregator} from
    "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";
import {MerklRewardAbstract__NoStorage} from "../../../misc/MerklRewardAbstract__NoStorage.sol";

contract PendleSyrupL2SY is PendleERC20SYUpgV2, MerklRewardAbstract__NoStorage {
    using PMath for uint256;
    using PMath for int256;

    address public immutable chainlinkFeed;
    address internal immutable underlyingAssetAddr;
    uint8 internal immutable underlyingAssetDecimals;
    uint8 internal immutable oracleDecimals;

    constructor(
        address _yieldToken,
        address _underlyingAssetAddr,
        address _chainlinkFeed,
        address _offchainRewardManager
    ) PendleERC20SYUpgV2(_yieldToken) MerklRewardAbstract__NoStorage(_offchainRewardManager) {
        chainlinkFeed = _chainlinkFeed;
        underlyingAssetAddr = _underlyingAssetAddr;
        underlyingAssetDecimals = IERC20Metadata(_underlyingAssetAddr).decimals();
        oracleDecimals = IChainlinkAggregator(_chainlinkFeed).decimals();
    }

    function exchangeRate() public view override returns (uint256 res) {
        (, int256 latestAnswer,,,) = IChainlinkAggregator(chainlinkFeed).latestRoundData();
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
