// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {IPExchangeRateOracle} from "../../../../interfaces/IPExchangeRateOracle.sol";
import {IMachineShareOracle} from "../../../../interfaces/Makina/IMachineShareOracle.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {PMath} from "../../../libraries/math/PMath.sol";

contract PendleMakinaExchangeRateOracle is IPExchangeRateOracle {
    using PMath for uint256;

    address public immutable sharePriceOracle;
    uint8 public immutable oracleDecimals;
    uint256 public immutable decimalsOffset;

    constructor(address _yieldToken, address _underlyingAsset, address _sharePriceOracle) {
        sharePriceOracle = _sharePriceOracle;
        oracleDecimals = IMachineShareOracle(_sharePriceOracle).decimals();
        decimalsOffset = IERC20Metadata(_yieldToken).decimals() - IERC20Metadata(_underlyingAsset).decimals();
    }

    function getExchangeRate() external view returns (uint256) {
        uint256 rawSharePrice = IMachineShareOracle(sharePriceOracle).getSharePrice();
        return rawSharePrice.divDown(10 ** (oracleDecimals + decimalsOffset));
    }
}
