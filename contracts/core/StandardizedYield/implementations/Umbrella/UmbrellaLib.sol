// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.20;

import "../../../../interfaces/AaveV3/IAaveStataToken.sol";
import "../../../../interfaces/IERC4626.sol";
import "../../../libraries/ArrayLib.sol";

library UmbrellaLib {
    function _depositATokenToUmbrella(
        address stataToken,
        address yieldToken,
        uint256 amountATokenIn
    ) internal returns (uint256 amountUmbrellaTokenOut) {
        return
            IERC4626(yieldToken).deposit(
                IAaveStataToken(stataToken).depositATokens(amountATokenIn, address(this)),
                address(this)
            );
    }

    function _depositToUmbrella(
        address tokenIn,
        uint256 amountDeposited,
        address[] memory path
    ) internal returns (uint256 amountUmbrellaTokenOut) {
        for (uint256 i = 0; i + 1 < path.length; i++) {
            if (tokenIn == path[i]) {
                address erc4626 = path[i + 1];
                (tokenIn, amountDeposited) = (erc4626, IERC4626(erc4626).deposit(amountDeposited, address(this)));
            }
        }
        return amountDeposited;
    }

    // AToken can also use this same function (replacing aToken with rootAsset)
    function _previewDepositToUmbrella(
        address tokenIn,
        uint256 amountTokenToDeposit,
        address[] memory path
    ) internal view returns (uint256 amountUmbrellaTokenOut) {
        for (uint256 i = 0; i + 1 < path.length; i++) {
            if (tokenIn == path[i]) {
                address erc4626 = path[i + 1];
                (tokenIn, amountTokenToDeposit) = (erc4626, IERC4626(erc4626).previewDeposit(amountTokenToDeposit));
            }
        }
        return amountTokenToDeposit;
    }
}
