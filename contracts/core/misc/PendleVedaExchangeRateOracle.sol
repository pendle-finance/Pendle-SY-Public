// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {IPExchangeRateOracle} from "../../interfaces/IPExchangeRateOracle.sol";
import {IVedaAccountant} from "../../interfaces/EtherFi/IVedaAccountant.sol";

contract PendleVedaExchangeRateOracle is IPExchangeRateOracle {
    address public immutable accountant;

    constructor(address _accountant) {
        accountant = _accountant;
    }

    function getExchangeRate() external view returns (uint256) {
        return IVedaAccountant(accountant).getRateSafe();
    }
}
