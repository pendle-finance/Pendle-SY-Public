// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../PendleERC4626UpgSYV2.sol";
import "../../../../interfaces/Reservoir/IReservoirCreditEnforcer.sol";
import "../../../../interfaces/Reservoir/IReservoirPSM.sol";

contract PendleReservoirWsrUSDSY is PendleERC4626UpgSYV2 {
    
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant RUSD = 0x09D4214C03D01F49544C0448DBE3A27f768F2b34;
    address public constant WSRUSD = 0xd3fD63209FA2D55B07A0f6db36C2f43900be3094;
    address public constant PSM = 0x4809010926aec940b550D34a46A52739f996D75D;
    address public constant CREDIT_ENFORSER = 0x04716DB62C085D9e08050fcF6F7D775A03d07720;

    uint256 public constant DECIMAL_FACTOR = 10 ** 12;
    constructor() PendleERC4626UpgSYV2(WSRUSD) {}

    function initialize() external initializer {
        __SYBaseUpg_init("SY Wrapped Savings rUSD", "SY-wsrUSD");

        _safeApproveInf(RUSD, PSM);
        _safeApproveInf(USDC, PSM);
        _safeApproveInf(RUSD, WSRUSD);
    }


    /*///////////////////////////////////////////////////////////////
                    DEPOSIT/REDEEM USING BASE TOKENS
    //////////////////////////////////////////////////////////////*/

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == USDC) {
            (tokenIn, amountDeposited) = (asset, IReservoirCreditEnforcer(CREDIT_ENFORSER).mintStablecoin(amountDeposited) * DECIMAL_FACTOR);
        }
        return super._deposit(tokenIn, amountDeposited);
    }

    function _redeem(
        address receiver,
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal override returns (uint256) {
        if (tokenOut == USDC) {
            uint256 amountRUSD = IERC4626(WSRUSD).redeem(amountSharesToRedeem, address(this), address(this));
            uint256 amtOut = amountRUSD / DECIMAL_FACTOR;
            IReservoirPSM(PSM).redeem(receiver, amtOut);
            return amtOut;
        } else {
            return super._redeem(receiver, tokenOut, amountSharesToRedeem);
        }
    }

    /*///////////////////////////////////////////////////////////////
                MISC FUNCTIONS FOR METADATA
    //////////////////////////////////////////////////////////////*/

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == USDC) {
            (tokenIn, amountTokenToDeposit) = (asset, amountTokenToDeposit * DECIMAL_FACTOR);
        }
        return super._previewDeposit(tokenIn, amountTokenToDeposit);
    }

    function _previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal view override returns (uint256 /*amountTokenOut*/) {
        if (tokenOut == yieldToken) {
            return amountSharesToRedeem * DECIMAL_FACTOR;
        }
        return super._previewRedeem(asset, amountSharesToRedeem) / (tokenOut == USDC ? DECIMAL_FACTOR : 1);
    }

    function getTokensIn() public view override returns (address[] memory res) {
        return ArrayLib.create(USDC, asset, yieldToken);
    }

    function getTokensOut() public view override returns (address[] memory res) {
        return ArrayLib.create(USDC, asset, yieldToken);
    }

    function isValidTokenIn(address token) public view override returns (bool) {
        return token == USDC || token == asset || token == yieldToken;
    }

    function isValidTokenOut(address token) public view override returns (bool) {
        return token == USDC || token == asset || token == yieldToken;
    }
}