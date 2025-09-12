// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../PendleERC20SYUpgV2.sol";
import {AggregatorV2V3Interface as IChainlinkAggregator} from
    "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

contract PendleWSTUSRArbitrumSY is PendleERC20SYUpgV2 {
    using PMath for int256;
    using PMath for uint256;

    address public constant WSTUSR = 0x66CFbD79257dC5217903A36293120282548E2254;
    address public constant USR = 0x2492D0006411Af6C8bbb1c8afc1B0197350a79e9;
    address public constant chainlinkFeed = 0x9BC7E5a6f1EED1C3217d2c63ad680DF83D84a906;

    constructor() PendleERC20SYUpgV2(WSTUSR) {}

    function exchangeRate() public view virtual override returns (uint256 res) {
        uint8 oracleDecimals = IChainlinkAggregator(chainlinkFeed).decimals();
        (, int256 latestAnswer,,,) = IChainlinkAggregator(chainlinkFeed).latestRoundData();
        return latestAnswer.Uint().divDown(10 ** oracleDecimals);
    }

    function assetInfo()
        external
        pure
        override
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.TOKEN, USR, 18);
    }
}
