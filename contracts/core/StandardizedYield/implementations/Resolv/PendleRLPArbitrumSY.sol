// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../PendleERC20SYUpgV2.sol";
import "../../../../interfaces/IPythPriceFeed.sol";

contract PendleRLPArbitrumSY is PendleERC20SYUpgV2 {
    using PMath for int256;
    using PMath for uint256;

    address public constant RLP = 0x35E5dB674D8e93a03d814FA0ADa70731efe8a4b9;
    address public constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
    address public constant PYTH_PRICE_FEED = 0xff1a0f4744e8582DF1aE09D5611b887B6a12925C;
    bytes32 public constant RLP_PRICE_FEED_ID = hex"796bcb684fdfbba2b071c165251511ab61f08c8949afd9e05665a26f69d9a839";

    int32 private constant SCALE_OFFSET = 6;

    constructor() PendleERC20SYUpgV2(RLP) {}

    function exchangeRate() public view virtual override returns (uint256) {
        IPythPriceFeed.Price memory p = IPythPriceFeed(PYTH_PRICE_FEED).getPriceUnsafe(RLP_PRICE_FEED_ID);

        int32 scale = p.expo + SCALE_OFFSET;
        uint256 rate;

        if (scale < 0) {
            rate = int256(p.price).Uint() / (10 ** uint32(-scale));
        } else {
            rate = int256(p.price).Uint() * (10 ** uint32(scale));
        }

        return rate;
    }

    function assetInfo()
        external
        view
        virtual
        override
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.TOKEN, USDC, 6);
    }
}
