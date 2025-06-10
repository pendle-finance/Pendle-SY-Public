// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../../SYBaseUpg.sol";
import "../../../../interfaces/InfiniFi/InfiniFiInterfaces.sol";

contract PendleInfiniFiiUSDSY is SYBaseUpg {
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant IUSD = 0x48f9e38f3070AD8945DFEae3FA70987722E3D89c;

    address public constant GATEWAY_PROXY = 0x3f04b65Ddbd87f9CE0A2e7Eb24d80e7fb87625b5;
    address public constant MINT_CONTROLLER = 0x49877d937B9a00d50557bdC3D87287b5c3a4C256;
    address public constant REDEEM_CONTROLLER = 0xCb1747E89a43DEdcF4A2b831a0D94859EFeC7601;

    constructor() SYBaseUpg(IUSD) {}

    function initialize() external initializer {
        __SYBaseUpg_init("SY infiniFi iUSD", "SY-iUSD");

        _safeApproveInf(IUSD, GATEWAY_PROXY);
        _safeApproveInf(USDC, GATEWAY_PROXY);
    }

    function _deposit(address tokenIn, uint256 amountDeposited)
        internal
        virtual
        override
        returns (uint256 /*amountSharesOut*/ )
    {
        if (tokenIn == USDC) {
            return InfiniFiGateway(GATEWAY_PROXY).mint(address(this), amountDeposited);
        }
        return amountDeposited;
    }

    function _redeem(address receiver, address tokenOut, uint256 amountSharesToRedeem)
        internal
        override
        returns (uint256)
    {
        if (tokenOut == USDC) {
            uint256 assetAmountOut = IRedeemController(REDEEM_CONTROLLER).receiptToAsset(amountSharesToRedeem);
            return InfiniFiGateway(GATEWAY_PROXY).redeem(receiver, amountSharesToRedeem, assetAmountOut);
        }

        _transferOut(tokenOut, receiver, amountSharesToRedeem);
        return amountSharesToRedeem;
    }

    function exchangeRate() public view virtual override returns (uint256) {
        // return number of USDC exchanged for 1 iUSD in 6 decimals
        return IRedeemController(REDEEM_CONTROLLER).receiptToAsset(1 ether);
    }

    function _previewDeposit(address tokenIn, uint256 amountTokenToDeposit)
        internal
        view
        override
        returns (uint256 /*amountSharesOut*/ )
    {
        if (tokenIn == USDC) {
            return IMintController(MINT_CONTROLLER).assetToReceipt(amountTokenToDeposit);
        }
        return amountTokenToDeposit;
    }

    function _previewRedeem(address tokenOut, uint256 amountSharesToRedeem)
        internal
        view
        override
        returns (uint256 /*amountTokenOut*/ )
    {
        if (tokenOut == USDC) {
            return IRedeemController(REDEEM_CONTROLLER).receiptToAsset(amountSharesToRedeem);
        }
        return amountSharesToRedeem;
    }

    function getTokensIn() public pure override returns (address[] memory res) {
        return ArrayLib.create(USDC);
    }

    function getTokensOut() public pure override returns (address[] memory res) {
        return ArrayLib.create(IUSD);
    }

    function isValidTokenIn(address token) public pure override returns (bool) {
        return token == USDC;
    }

    function isValidTokenOut(address token) public pure override returns (bool) {
        return token == IUSD;
    }

    function assetInfo() external view returns (AssetType assetType, address assetAddress, uint8 assetDecimals) {
        return (AssetType.TOKEN, USDC, IERC20Metadata(USDC).decimals());
    }
}
