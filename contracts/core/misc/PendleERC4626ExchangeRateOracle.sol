// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {IPExchangeRateOracle} from "../../interfaces/IPExchangeRateOracle.sol";
import {IERC4626} from "../../interfaces/IERC4626.sol";

contract PendleERC4626ExchangeRateOracle is IPExchangeRateOracle {
    address public immutable erc4626;

    constructor(address _erc4626) {
        erc4626 = _erc4626;
    }

    function getExchangeRate() external view returns (uint256) {
        return IERC4626(erc4626).convertToAssets(1e18);
    }
}
