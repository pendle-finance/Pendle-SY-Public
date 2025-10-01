// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../PendleERC20SYUpgV2.sol";
import {AggregatorV2V3Interface as IChainlinkAggregator} from
    "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";
import {MerklRewardAbstract__NoStorage} from "../../../misc/MerklRewardAbstract__NoStorage.sol";

contract PendleSUSDaiL2SY is PendleERC20SYUpgV2, MerklRewardAbstract__NoStorage {
    using PMath for int256;

    address public immutable usdai;
    address public immutable chainlinkExchangeRateOracle;

    constructor(address _susdai, address _usdai, address _chainlinkExchangeRateOracle, address _offchainRewardManager)
        PendleERC20SYUpgV2(_susdai)
        MerklRewardAbstract__NoStorage(_offchainRewardManager)
    {
        usdai = _usdai;
        chainlinkExchangeRateOracle = _chainlinkExchangeRateOracle;
    }

    function exchangeRate() public view override returns (uint256) {
        (, int256 latestAnswer,,,) = IChainlinkAggregator(chainlinkExchangeRateOracle).latestRoundData();
        return latestAnswer.Uint();
    }

    function assetInfo()
        external
        view
        override
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.TOKEN, usdai, IERC20Metadata(usdai).decimals());
    }
}
