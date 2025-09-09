// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../PendleERC20SYUpgV2.sol";
import {AggregatorV2V3Interface as IChaosPushOracle} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

contract PendleGMV2SingleTokenSY is PendleERC20SYUpgV2 {
    using PMath for int256;
    using PMath for uint256;

    error OraclePriceNotSet();

    address public immutable feeTrackerFeed;
    uint8 internal immutable oracleDecimals;

    constructor(address _yieldToken, address _feeTrackerFeed) PendleERC20SYUpgV2(_yieldToken) {
        feeTrackerFeed = _feeTrackerFeed;
        oracleDecimals = IChaosPushOracle(feeTrackerFeed).decimals();
    }

    function exchangeRate() public view override returns (uint256 res) {
        int256 latestAnswer = IChaosPushOracle(feeTrackerFeed).latestAnswer();
        if (latestAnswer == 0) revert OraclePriceNotSet();

        return latestAnswer.Uint().divDown(10 ** oracleDecimals);
    }

    function assetInfo()
        external
        view
        override
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.LIQUIDITY, yieldToken, IERC20Metadata(yieldToken).decimals());
    }
}
