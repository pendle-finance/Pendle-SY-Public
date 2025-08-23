// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../../../interfaces/Lombard/ILBTCOracle.sol";
import "../../../../interfaces/IPExchangeRateOracle.sol";

contract PendleLBTCExchangeRateOracle is IPExchangeRateOracle {
    address public immutable oracle;

    constructor(address _oracle) {
        oracle = _oracle;
    }

    function getExchangeRate() external view returns (uint256) {
        return ILBTCOracle(oracle).getRate();
    }
}
