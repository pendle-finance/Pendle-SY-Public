// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPExchangeRateOracle} from "../../../../interfaces/IPExchangeRateOracle.sol";
import {AggregatorV2V3Interface as IChainlinkAggregator} from
    "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

contract PendleRsETHOracle is IPExchangeRateOracle {
    address public immutable chainlinkOracle;

    constructor(address _chainlinkOracle) {
        chainlinkOracle = _chainlinkOracle;
    }

    function getExchangeRate() external view returns (uint256) {
        (, int256 latestAnswer,,,) = IChainlinkAggregator(chainlinkOracle).latestRoundData();
        return uint256(latestAnswer);
    }
}
