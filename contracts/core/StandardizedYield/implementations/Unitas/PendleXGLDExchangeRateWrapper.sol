// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPExchangeRateOracle} from "../../../../interfaces/IPExchangeRateOracle.sol";

interface IXGLDOracle {
    function exchangeRate() external view returns (uint256);
}

contract PendleXGLDExchangeRateWrapper is IPExchangeRateOracle {
    address public constant oracle = 0x7Bbe7FDCd6BdFFd7F767a9531b6210b87b3e46E7;

    function getExchangeRate() external view returns (uint256) {
        return IXGLDOracle(oracle).exchangeRate() * (10 ** 12);
    }
}
