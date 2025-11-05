// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../Adapter/extensions/PendleERC4626NoRedeemWithAdapterSY.sol";
import "../../../../interfaces/Strata/IStrataTranche.sol";
import "../../../../interfaces/Strata/IStrataCDO.sol";

contract PendleStrataSRUSDESY is PendleERC4626NoRedeemWithAdapterSY {
    address public immutable srUSDe;
    address public immutable sUSDe;
    address public immutable cdo;

    constructor(
        address _srUSDe,
        address _sUSDe,
        address _offchainRewardManager
    ) PendleERC4626NoRedeemWithAdapterSY(_srUSDe, _offchainRewardManager) {
        srUSDe = _srUSDe;
        sUSDe = _sUSDe;
        cdo = IStrataTranche(_srUSDe).cdo();
    }

    function _redeem(
        address receiver,
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal override returns (uint256) {
        if (tokenOut == srUSDe) {
            _transferOut(srUSDe, receiver, amountSharesToRedeem);
            return amountSharesToRedeem;
        }
        return IStrataTranche(srUSDe).redeem(sUSDe, amountSharesToRedeem, receiver, address(this));
    }

    function _previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal view virtual override returns (uint256 /*amountTokenOut*/) {
        if (tokenOut == srUSDe) {
            return amountSharesToRedeem;
        }

        uint256 baseAssets = IERC4626(srUSDe).previewRedeem(amountSharesToRedeem);
        uint256 tokenAssets = IStrataCDO(cdo).strategy().convertToTokens(sUSDe, baseAssets, Math.Rounding.Down);

        return tokenAssets;
    }

    function getTokensOut() public view virtual override returns (address[] memory res) {
        return ArrayLib.create(yieldToken, sUSDe);
    }

    function isValidTokenOut(address token) public view virtual override returns (bool) {
        return token == yieldToken || token == sUSDe;
    }
}
