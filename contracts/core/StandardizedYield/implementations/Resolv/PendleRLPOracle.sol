// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../../../../interfaces/IPExchangeRateOracle.sol";

interface IRlpPriceStorage {
    function lastPrice() external view returns (uint256 price, uint256 timestamp);
}

contract PendleRLPOracle is IPExchangeRateOracle {
    address public constant rlpPriceStorage = 0xaE2364579D6cB4Bbd6695846C1D595cA9AF3574d;

    function getExchangeRate() external view override returns (uint256) {
        (uint256 price, ) = IRlpPriceStorage(rlpPriceStorage).lastPrice();
        return price;
    }
}