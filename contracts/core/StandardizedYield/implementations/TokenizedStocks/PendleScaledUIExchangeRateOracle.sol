// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {IPExchangeRateOracle} from "../../../../interfaces/IPExchangeRateOracle.sol";
import {IScaledUIAmount} from "../../../../interfaces/IScaledUIAmount.sol";
import {IOraclePausable} from "../../../../interfaces/IOraclePausable.sol";

contract PendleScaledUIExchangeRateOracle is IPExchangeRateOracle {
    address public immutable stockToken;

    constructor(address _stockToken) {
        stockToken = _stockToken;
    }

    function getExchangeRate() external view returns (uint256) {
        require(!IOraclePausable(stockToken).oraclePaused(), "PSUERO: issuer paused");
        return IScaledUIAmount(stockToken).uiMultiplier();
    }
}
