// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPExchangeRateOracle} from "../../interfaces/IPExchangeRateOracle.sol";
import {AggregatorV2V3Interface as IChainlinkAggregator} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";
import {PMath} from "../libraries/math/PMath.sol";

contract PendleChainlinkExchangeRateWrapper is IPExchangeRateOracle {
    using PMath for int256;
    using PMath for uint256;

    address public immutable chainlinkFeed;
    uint256 public immutable scalingDivisor;

    constructor(address _chainlinkFeed, uint8 _tokenDecimalsOffset) {
        chainlinkFeed = _chainlinkFeed;
        scalingDivisor = 10 ** (IChainlinkAggregator(_chainlinkFeed).decimals() + _tokenDecimalsOffset);
    }

    function getExchangeRate() external view returns (uint256) {
        (, int256 latestAnswer, , , ) = IChainlinkAggregator(chainlinkFeed).latestRoundData();
        return latestAnswer.Uint().divDown(scalingDivisor);
    }
}
