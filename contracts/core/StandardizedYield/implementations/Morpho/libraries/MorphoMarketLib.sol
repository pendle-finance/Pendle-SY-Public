// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {Id, MarketParams, Market, IMorpho, IIrm} from "../../../../../interfaces/Morpho/IMorpho.sol";

/// @dev Faithful port of Morpho's SharesMathLib, MathLib and
/// MorphoBalancesLib.expectedMarketBalances (morpho-org/morpho-blue).
library MorphoMarketLib {
    uint256 internal constant WAD = 1e18;
    uint256 internal constant VIRTUAL_SHARES = 1e6;
    uint256 internal constant VIRTUAL_ASSETS = 1;

    function id(MarketParams memory marketParams) internal pure returns (Id) {
        return Id.wrap(keccak256(abi.encode(marketParams)));
    }

    function toSharesDown(uint256 assets, uint256 totalAssets, uint256 totalShares) internal pure returns (uint256) {
        return mulDivDown(assets, totalShares + VIRTUAL_SHARES, totalAssets + VIRTUAL_ASSETS);
    }

    function toAssetsDown(uint256 shares, uint256 totalAssets, uint256 totalShares) internal pure returns (uint256) {
        return mulDivDown(shares, totalAssets + VIRTUAL_ASSETS, totalShares + VIRTUAL_SHARES);
    }

    function wMulDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD);
    }

    function mulDivDown(uint256 x, uint256 y, uint256 d) internal pure returns (uint256) {
        return (x * y) / d;
    }

    function wTaylorCompounded(uint256 x, uint256 n) internal pure returns (uint256) {
        uint256 firstTerm = x * n;
        uint256 secondTerm = mulDivDown(firstTerm, firstTerm, 2 * WAD);
        uint256 thirdTerm = mulDivDown(secondTerm, firstTerm, 3 * WAD);
        return firstTerm + secondTerm + thirdTerm;
    }

    function expectedSupplyBalances(
        IMorpho morpho,
        MarketParams memory marketParams
    ) internal view returns (uint256 totalSupplyAssets, uint256 totalSupplyShares) {
        Market memory market = morpho.market(id(marketParams));

        uint256 elapsed = block.timestamp - market.lastUpdate;

        if (elapsed != 0 && market.totalBorrowAssets != 0 && marketParams.irm != address(0)) {
            uint256 borrowRate = IIrm(marketParams.irm).borrowRateView(marketParams, market);
            uint256 interest = wMulDown(market.totalBorrowAssets, wTaylorCompounded(borrowRate, elapsed));
            market.totalBorrowAssets += _toUint128(interest);
            market.totalSupplyAssets += _toUint128(interest);

            if (market.fee != 0) {
                uint256 feeAmount = wMulDown(interest, market.fee);
                uint256 feeShares = toSharesDown(
                    feeAmount,
                    market.totalSupplyAssets - feeAmount,
                    market.totalSupplyShares
                );
                market.totalSupplyShares += _toUint128(feeShares);
            }
        }

        return (market.totalSupplyAssets, market.totalSupplyShares);
    }

    function _toUint128(uint256 x) private pure returns (uint128) {
        require(x <= type(uint128).max, "MML: uint128 overflow");
        return uint128(x);
    }
}
