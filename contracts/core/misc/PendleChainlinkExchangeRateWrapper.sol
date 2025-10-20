// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPExchangeRateOracle} from "../../interfaces/IPExchangeRateOracle.sol";
import {AggregatorV2V3Interface as IChainlinkAggregator} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";
import {PMath} from "../libraries/math/PMath.sol";

contract PendleChainlinkExchangeRateWrapper is IPExchangeRateOracle {
    using PMath for int256;
    using PMath for uint256;

    address public immutable chainlinkFeed;
    uint8 public immutable oracleDecimals;
    int8 public immutable tokenDecimalsOffset;

    constructor(address _chainlinkFeed, int8 _tokenDecimalsOffset) {
        chainlinkFeed = _chainlinkFeed;
        oracleDecimals = IChainlinkAggregator(_chainlinkFeed).decimals();
        tokenDecimalsOffset = _tokenDecimalsOffset;
    }

    function getExchangeRate() external view returns (uint256 res) {
        (, int256 latestAnswer, , , ) = IChainlinkAggregator(chainlinkFeed).latestRoundData();

        res = latestAnswer.Uint().divDown(10 ** oracleDecimals);
        if (tokenDecimalsOffset < 0) {
            res = res * 10 ** uint8(-tokenDecimalsOffset);
        } else {
            res = res / 10 ** uint8(tokenDecimalsOffset);
        }
    }
}
