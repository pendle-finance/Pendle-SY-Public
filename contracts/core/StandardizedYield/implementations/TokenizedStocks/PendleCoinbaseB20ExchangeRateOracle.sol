// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {IPExchangeRateOracle} from "../../../../interfaces/IPExchangeRateOracle.sol";
import {IOracleRegistry} from "../../../../interfaces/Coinbase/IOracleRegistry.sol";

contract PendleCoinbaseB20ExchangeRateOracle is IPExchangeRateOracle {
    address public immutable stockToken;
    address public immutable oracleRegistry;

    constructor(address _stockToken, address _oracleRegistry) {
        stockToken = _stockToken;
        oracleRegistry = _oracleRegistry;
    }

    function getExchangeRate() external view returns (uint256) {
        (uint256 multiplier, bool paused) = IOracleRegistry(oracleRegistry).getOracleParams(stockToken);
        require(!paused, "PCBERO: issuer paused");
        return multiplier;
    }
}
