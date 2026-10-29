// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {IPExchangeRateOracle} from "../../../../interfaces/IPExchangeRateOracle.sol";
import {IMachine} from "../../../../interfaces/Makina/IMachine.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract PendleMakinaMachineExchangeRateOracle is IPExchangeRateOracle {
    address public immutable machine;
    uint256 public immutable sharesForRate;

    constructor(address _machine) {
        machine = _machine;
        uint256 shareDecimals = IERC20Metadata(IMachine(_machine).shareToken()).decimals();
        uint256 assetDecimals = IERC20Metadata(IMachine(_machine).accountingToken()).decimals();
        sharesForRate = 10 ** (18 + shareDecimals - assetDecimals);
    }

    function getExchangeRate() external view returns (uint256) {
        return IMachine(machine).convertToAssets(sharesForRate);
    }
}
