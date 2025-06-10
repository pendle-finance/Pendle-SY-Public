// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../PendleERC4626UpgSYV2.sol";
import "../../../../interfaces/Balancer/IRateProvider.sol";

contract PendleYearnBalancerLPSY is PendleERC4626UpgSYV2 {
    using PMath for uint256;

    constructor(address _yVault) PendleERC4626UpgSYV2(_yVault) {}

    function exchangeRate() public view virtual override returns (uint256) {
        // Balancer pools always have rate in 18 decimals
        return IERC4626(yieldToken).convertToAssets(IRateProvider(asset).getRate());
    }

    function assetInfo()
        external
        view
        virtual
        override
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.LIQUIDITY, asset, IERC20Metadata(asset).decimals());
    }
}
