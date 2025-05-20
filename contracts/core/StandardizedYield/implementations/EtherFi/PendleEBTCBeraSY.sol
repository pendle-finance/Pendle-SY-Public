// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.23;

import "../PendleERC20SYUpg.sol";
import "../../../../interfaces/EtherFi/IVedaTeller.sol";
import "../../../../interfaces/EtherFi/IVedaAccountant.sol";

contract PendleEBTCBeraSY is PendleERC20SYUpg {
    // solhint-disable immutable-vars-naming
    // solhint-disable const-name-snakecase
    // solhint-disable ordering

    address public constant eBTC = 0x657e8C867D8B37dCC18fA4Caead9C45EB088C642;
    address public constant wBTC = 0x0555E30da8f98308EdB960aa94C0Db47230d2B9c;
    address public constant LBTC = 0xecAc9C5F704e954931349Da37F60E39f515c11c1;
    address public constant vedaTeller = 0x6Ee3aaCcf9f2321E49063C4F8da775DdBd407268;

    uint256 public constant ONE_SHARE = 10 ** 8;
    uint256 public constant PREMIUM_SHARE_BPS = 10 ** 4;

    address public immutable vedaAccountant;

    constructor() PendleERC20SYUpg(eBTC) {
        vedaAccountant = IVedaTeller(vedaTeller).accountant();
    }

    function approveAllForTeller() external {
        _safeApproveInf(wBTC, eBTC);
        _safeApproveInf(LBTC, eBTC);
    }

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == eBTC) {
            return amountDeposited;
        }
        return IVedaTeller(vedaTeller).deposit(tokenIn, amountDeposited, 0);
    }

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view virtual override returns (uint256 amountSharesOut) {
        if (tokenIn == eBTC) {
            return amountTokenToDeposit;
        }
        uint256 rate = IVedaAccountant(vedaAccountant).getRateInQuoteSafe(tokenIn);
        amountSharesOut = (amountTokenToDeposit * ONE_SHARE) / rate;

        IVedaTeller.Asset memory data = IVedaTeller(vedaTeller).assetData(tokenIn);
        amountSharesOut = (amountSharesOut * (PREMIUM_SHARE_BPS - data.sharePremium)) / PREMIUM_SHARE_BPS;
    }

    function isValidTokenIn(address token) public pure override returns (bool) {
        return token == eBTC || token == wBTC || token == LBTC;
    }

    function getTokensIn() public pure override returns (address[] memory res) {
        return ArrayLib.create(wBTC, eBTC, LBTC);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        require(amount > 0, "transfer zero amount");
    }
}
