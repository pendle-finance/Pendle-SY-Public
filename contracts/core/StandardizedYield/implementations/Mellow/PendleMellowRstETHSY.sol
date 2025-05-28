// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../PendleERC4626NoRedeemUpgSY.sol";
import "../../../../interfaces/IPTokenWithSupplyCap.sol";
import "../../../../interfaces/IWstETH.sol";

contract PendleMellowRstETHSY is PendleERC4626NoRedeemUpgSY, IPTokenWithSupplyCap {
    error SupplyCapExceeded(uint256 totalSupply, uint256 supplyCap);

    constructor() PendleERC4626NoRedeemUpgSY(0x7a4EffD87C2f3C55CA251080b1343b605f327E3a) {}

    function getAbsoluteSupplyCap() external view virtual returns (uint256) {
        return IERC4626(yieldToken).maxMint(address(this));
    }

    function getAbsoluteTotalSupply() external view virtual returns (uint256) {
        return IERC20(yieldToken).totalSupply();
    }

    function exchangeRate() public view virtual override returns (uint256) {
        return IERC4626(yieldToken).convertToAssets(IWstETH(asset).stEthPerToken());
    }

    function assetInfo()
        external
        view
        virtual
        override
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.TOKEN, IWstETH(asset).stETH(), 18);
    }
}