// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {IPExchangeRateOracle} from "../../../../interfaces/IPExchangeRateOracle.sol";
import {ISyntheticSharesOracle} from "../../../../interfaces/Ondo/ISyntheticSharesOracle.sol";

contract PendleOndoExchangeRateOracle is IPExchangeRateOracle {
    address public immutable gmToken;
    address public immutable syntheticSharesOracle;

    constructor(address _gmToken, address _syntheticSharesOracle) {
        gmToken = _gmToken;
        syntheticSharesOracle = _syntheticSharesOracle;
    }

    function getExchangeRate() external view returns (uint256) {
        (uint128 sValue, bool paused) = ISyntheticSharesOracle(syntheticSharesOracle).getSValue(gmToken);
        require(!paused, "POERO: issuer paused");
        return sValue;
    }
}
