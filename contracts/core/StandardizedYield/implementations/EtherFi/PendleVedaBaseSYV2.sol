// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.23;

import "../PendleERC20SYUpgV2.sol";
import "../../../../interfaces/EtherFi/IVedaTeller.sol";
import "../../../../interfaces/EtherFi/IVedaAccountant.sol";

abstract contract PendleVedaBaseSYV2 is PendleERC20SYUpgV2 {
    using PMath for uint256;

    // solhint-disable immutable-vars-naming
    // solhint-disable const-name-snakecase
    // solhint-disable ordering
    uint256 public constant PREMIUM_SHARE_BPS = 10 ** 4;

    uint256 public immutable ONE_SHARE;
    address public immutable vedaTeller;
    address public immutable vedaAccountant;

    constructor(address _boringVault, address _vedaTeller, uint256 _ONE_SHARE) PendleERC20SYUpgV2(_boringVault) {
        vedaTeller = _vedaTeller;
        vedaAccountant = IVedaTeller(_vedaTeller).accountant();
        ONE_SHARE = _ONE_SHARE;
    }

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == yieldToken) {
            return amountDeposited;
        }
        return IVedaTeller(vedaTeller).deposit(tokenIn, amountDeposited, 0);
    }

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view virtual override returns (uint256 amountSharesOut) {
        if (tokenIn == yieldToken) {
            return amountTokenToDeposit;
        }
        uint256 rate = IVedaAccountant(vedaAccountant).getRateInQuoteSafe(tokenIn);
        amountSharesOut = (amountTokenToDeposit * ONE_SHARE) / rate;

        IVedaTeller.Asset memory data = IVedaTeller(vedaTeller).assetData(tokenIn);
        amountSharesOut = (amountSharesOut * (PREMIUM_SHARE_BPS - data.sharePremium)) / PREMIUM_SHARE_BPS;
    }
}
