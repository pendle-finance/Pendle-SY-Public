// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

import "../../SYBaseUpg.sol";
import "../../../../interfaces/IERC4626.sol";

import "../PendleERC4626UpgSYV2.sol";

interface IInfiniFiGateway {
    function stake(address _to, uint256 _receiptTokens) external returns (uint256);

    function redeem(address _to, uint256 _amount, uint256 _minAssetsOut) external returns (uint256);

    function unstake(address _to, uint256 _stakedTokens) external returns (uint256);

    function getAddress(string memory _name) external view returns (address);

    function mintAndStake(address _to, uint256 _amount) external returns (uint256);
}

interface IYieldSharing {
    function vested() external view returns (uint256);
}

interface IRedeemController {
    function receiptToAsset(uint256 _receiptAmount) external view returns (uint256);
}

interface IMintController {
    function assetToReceipt(uint256 _assetAmount) external view returns (uint256);
}

contract PendleInfinifiSIUSD is PendleERC4626UpgSYV2 {
    using PMath for uint256;

    address public constant IUSD = 0x48f9e38f3070AD8945DFEae3FA70987722E3D89c;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant SIUSD = 0xDBDC1Ef57537E34680B898E1FEBD3D68c7389bCB;
    address public constant GATEWAY = 0x3f04b65Ddbd87f9CE0A2e7Eb24d80e7fb87625b5;

    error UnsupportedToken(address _token);

    constructor() PendleERC4626UpgSYV2(SIUSD) {}

    function initialize(string memory _name, string memory _symbol) external override initializer {
        __SYBaseUpg_init(_name, _symbol);
        _safeApproveInf(IUSD, GATEWAY);
        _safeApproveInf(USDC, GATEWAY);
        _safeApproveInf(SIUSD, GATEWAY);
    }

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == IUSD) {
            return IInfiniFiGateway(GATEWAY).stake(address(this), amountDeposited);
        }

        if (tokenIn == USDC) {
            uint256 amountBefore = IERC4626(SIUSD).balanceOf(address(this));
            IInfiniFiGateway(GATEWAY).mintAndStake(address(this), amountDeposited);
            uint256 amountAfter = IERC4626(SIUSD).balanceOf(address(this));
            return amountAfter - amountBefore;
        }

        if (tokenIn == SIUSD) {
            return amountDeposited;
        }

        revert UnsupportedToken(tokenIn);
    }

    function _redeem(
        address receiver,
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal override returns (uint256 /*amountTokenOut*/) {
        if (tokenOut == IUSD) {
            return IInfiniFiGateway(GATEWAY).unstake(receiver, amountSharesToRedeem);
        }

        if (tokenOut == USDC) {
            // unstake from siUSD to iUSD
            uint256 receiptOut = IInfiniFiGateway(GATEWAY).unstake(address(this), amountSharesToRedeem);
            address redeemController = IInfiniFiGateway(GATEWAY).getAddress("redeemController");
            // convert iUSD to USDC
            uint256 assetsOut = IRedeemController(redeemController).receiptToAsset(receiptOut);
            // redeem iUSD, assetsOut is in USDC
            return IInfiniFiGateway(GATEWAY).redeem(receiver, receiptOut, assetsOut);
        }

        if (tokenOut == SIUSD) {
            _transferOut(yieldToken, receiver, amountSharesToRedeem);
            return amountSharesToRedeem;
        }

        revert UnsupportedToken(tokenOut);
    }

    // returns exchange rate in USDC
    function exchangeRate() public view override returns (uint256) {
        address redeemController = IInfiniFiGateway(GATEWAY).getAddress("redeemController");
        uint256 receiptOut = _convertToAssets(PMath.ONE);
        return IRedeemController(redeemController).receiptToAsset(receiptOut);
    }

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == IUSD) {
            return _convertToShares(amountTokenToDeposit);
        }

        if (tokenIn == USDC) {
            address mintController = IInfiniFiGateway(GATEWAY).getAddress("mintController");
            // preview USDC to iUSD conversion
            uint256 receiptTokens = IMintController(mintController).assetToReceipt(amountTokenToDeposit);
            return _convertToShares(receiptTokens);
        }

        if (tokenIn == SIUSD) {
            return amountTokenToDeposit;
        }

        revert UnsupportedToken(tokenIn);
    }

    function _previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal view override returns (uint256 /*amountTokenOut*/) {
        if (tokenOut == IUSD) {
            return _convertToAssets(amountSharesToRedeem);
        }

        if (tokenOut == USDC) {
            // see how much iUSD we get from redeeming siUSD
            uint256 receiptOut = _convertToAssets(amountSharesToRedeem);
            address redeemController = IInfiniFiGateway(GATEWAY).getAddress("redeemController");
            // convert iUSD to USDC
            return IRedeemController(redeemController).receiptToAsset(receiptOut);
        }

        if (tokenOut == SIUSD) {
            return amountSharesToRedeem;
        }

        revert UnsupportedToken(tokenOut);
    }

    function _convertToShares(uint256 _receiptIn) internal view returns (uint256 /* _sharesOut */) {
        uint256 vested = IYieldSharing(IInfiniFiGateway(GATEWAY).getAddress("yieldSharing")).vested();
        uint256 supply = IERC4626(SIUSD).totalSupply();
        uint256 assets = IERC4626(SIUSD).totalAssets() + vested;
        return supply == 0 ? _receiptIn : ((_receiptIn * supply) / assets);
    }

    function _convertToAssets(uint256 _sharesIn) internal view returns (uint256 /* _assetsOut */) {
        uint256 vested = IYieldSharing(IInfiniFiGateway(GATEWAY).getAddress("yieldSharing")).vested();
        uint256 supply = IERC4626(SIUSD).totalSupply();
        uint256 assets = IERC4626(SIUSD).totalAssets() + vested;
        return supply == 0 ? _sharesIn : (_sharesIn * assets) / supply;
    }

    function getTokensIn() public pure override returns (address[] memory res) {
        res = new address[](3);
        res[0] = IUSD;
        res[1] = SIUSD;
        res[2] = USDC;
    }

    function getTokensOut() public pure override returns (address[] memory res) {
        res = new address[](3);
        res[0] = IUSD;
        res[1] = SIUSD;
        res[2] = USDC;
    }

    function isValidTokenIn(address token) public pure override returns (bool) {
        return token == IUSD || token == SIUSD || token == USDC;
    }

    function isValidTokenOut(address token) public pure override returns (bool) {
        return token == IUSD || token == SIUSD || token == USDC;
    }

    function assetInfo()
        external
        pure
        override
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.TOKEN, USDC, 6);
    }
}
