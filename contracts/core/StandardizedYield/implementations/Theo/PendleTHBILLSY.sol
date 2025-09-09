// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../PendleERC20SYUpgV2.sol";
import "../../../../interfaces/IRedstonePriceFeed.sol";

contract PendleTHBILLSY is PendleERC20SYUpgV2 {
    using PMath for uint256;
    using PMath for int256;

    address public immutable redstoneFeed;
    address internal immutable underlyingAssetAddr;
    uint8 internal immutable underlyingAssetDecimals;

    constructor(
        address _yieldToken,
        address _redstoneFeed,
        address _underlyingAssetAddr,
        uint8 _underlyingAssetDecimals
    ) PendleERC20SYUpgV2(_yieldToken) {
        redstoneFeed = _redstoneFeed;
        underlyingAssetAddr = _underlyingAssetAddr;
        underlyingAssetDecimals = _underlyingAssetDecimals;
    }

    function exchangeRate() public view override returns (uint256) {
        uint8 oracleDecimals = IRedstonePriceFeed(redstoneFeed).decimals();
        (, int256 latestAnswer, , , ) = IRedstonePriceFeed(redstoneFeed).latestRoundData();
        return latestAnswer.Uint().divDown(10 ** oracleDecimals);
    }

    function assetInfo()
        external
        view
        override
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.TOKEN, underlyingAssetAddr, underlyingAssetDecimals);
    }
}
