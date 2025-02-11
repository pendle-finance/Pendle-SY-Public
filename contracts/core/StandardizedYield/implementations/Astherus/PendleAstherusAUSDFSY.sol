// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../../SYBaseUpg.sol";
import "../../../../interfaces/Astherus/IAstherusEarn.sol";

contract PendleAstherusAUSDFSY is SYBaseUpg {
    address public constant AUSDF = 0x917AF46B3C3c6e1Bb7286B9F59637Fb7C65851Fb;
    address public constant USDF = 0x5A110fC00474038f6c02E89C707D638602EA44B5;
    address public constant EARN = 0xdB57a53C428a9faFcbFefFB6dd80d0f427543695;

    constructor() SYBaseUpg(AUSDF) {}

    function initialize() external initializer {
        __SYBaseUpg_init("SY Astherus asUSDF", "SY-asUSDF");
        _safeApproveInf(USDF, EARN);
    }

    /*///////////////////////////////////////////////////////////////
                    DEPOSIT/REDEEM USING BASE TOKENS
    //////////////////////////////////////////////////////////////*/

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn != AUSDF) {
            uint256 preBalance = _selfBalance(AUSDF);
            IAstherusEarn(EARN).deposit(amountDeposited);
            amountDeposited = _selfBalance(AUSDF) - preBalance;
        }
        return amountDeposited;
    }

    function _redeem(
        address receiver,
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal override returns (uint256) {
        _transferOut(AUSDF, receiver, amountSharesToRedeem);
        return amountSharesToRedeem;
    }

    /*///////////////////////////////////////////////////////////////
                               EXCHANGE-RATE
    //////////////////////////////////////////////////////////////*/

    function exchangeRate() public view virtual override returns (uint256) {
        return IAstherusEarn(EARN).exchangePrice();
    }

    /*///////////////////////////////////////////////////////////////
                MISC FUNCTIONS FOR METADATA
    //////////////////////////////////////////////////////////////*/

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == AUSDF) return amountTokenToDeposit;
        return PMath.divDown(amountTokenToDeposit, IAstherusEarn(EARN).exchangePrice());
    }

    function _previewRedeem(
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal pure override returns (uint256 /*amountTokenOut*/) {
        return amountSharesToRedeem;
    }

    function getTokensIn() public pure override returns (address[] memory res) {
        return ArrayLib.create(USDF, AUSDF);
    }

    function getTokensOut() public pure override returns (address[] memory res) {
        return ArrayLib.create(AUSDF);
    }

    function isValidTokenIn(address token) public pure override returns (bool) {
        return token == USDF || token == AUSDF;
    }

    function isValidTokenOut(address token) public pure override returns (bool) {
        return token == AUSDF;
    }

    function assetInfo() external view returns (AssetType assetType, address assetAddress, uint8 assetDecimals) {
        return (AssetType.TOKEN, USDF, IERC20Metadata(USDF).decimals());
    }
}
