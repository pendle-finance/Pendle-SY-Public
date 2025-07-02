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

    constructor() PendleERC4626UpgSYV2(SIUSD) {}

    function initialize(string memory _name, string memory _symbol) external virtual initializer {
        __SYBaseUpg_init(_name, _symbol);
        _safeApproveInf(IUSD, GATEWAY);
        _safeApproveInf(USDC, GATEWAY);
        _safeApproveInf(SIUSD, GATEWAY);
    }

    function _deposit(address tokenIn, uint256 amountDeposited)
        internal
        virtual
        override
        returns (uint256 /*amountSharesOut*/ )
    {
        if (tokenIn == IUSD) {
            return IInfiniFiGateway(GATEWAY).stake(address(this), amountDeposited);
        } else if (tokenIn == USDC) {
            return IInfiniFiGateway(GATEWAY).mintAndStake(address(this), amountDeposited);
        }
        return amountDeposited;
    }

    function _redeem(address receiver, address tokenOut, uint256 amountSharesToRedeem)
        internal
        virtual
        override
        returns (uint256 amountTokenOut)
    {
        if (tokenOut == IUSD) {
            return IInfiniFiGateway(GATEWAY).unstake(receiver, amountSharesToRedeem);
        } else if (tokenOut == USDC) {
            uint256 unstaked = IInfiniFiGateway(GATEWAY).unstake(address(this), amountSharesToRedeem);
            uint256 assetsOut = IERC4626(yieldToken).convertToAssets(unstaked);
            return IInfiniFiGateway(GATEWAY).redeem(receiver, unstaked, assetsOut);
        }
        return amountTokenOut;
    }

    function exchangeRate() public view virtual override returns (uint256) {
        return IERC4626(yieldToken).convertToAssets(PMath.ONE);
    }

    function _previewDeposit(address tokenIn, uint256 amountTokenToDeposit)
        internal
        view
        virtual
        override
        returns (uint256 /*amountSharesOut*/ )
    {
        if (tokenIn == IUSD) {
            return IERC4626(SIUSD).previewDeposit(amountTokenToDeposit);
        } else if (tokenIn == USDC) {
            address mintController = IInfiniFiGateway(GATEWAY).getAddress("mintController");
            uint256 receiptOut = IMintController(mintController).assetToReceipt(amountTokenToDeposit);
            return IERC4626(SIUSD).previewDeposit(receiptOut);
        }
        return amountTokenToDeposit;
    }

    function _previewRedeem(address tokenOut, uint256 amountSharesToRedeem)
        internal
        view
        virtual
        override
        returns (uint256 /*amountTokenOut*/ )
    {
        if (tokenOut == IUSD) {
            return IERC4626(SIUSD).previewRedeem(amountSharesToRedeem);
        } else if (tokenOut == USDC) {
            uint256 receiptOut = IERC4626(SIUSD).previewRedeem(amountSharesToRedeem);
            address redeemController = IInfiniFiGateway(GATEWAY).getAddress("redeemController");
            return IRedeemController(redeemController).receiptToAsset(receiptOut);
        }
        return amountSharesToRedeem;
    }

    function getTokensIn() public view virtual override returns (address[] memory res) {
        res = new address[](3);
        res[0] = IUSD;
        res[1] = SIUSD;
        res[2] = USDC;
    }

    function getTokensOut() public view virtual override returns (address[] memory res) {
        res = new address[](3);
        res[0] = IUSD;
        res[1] = SIUSD;
        res[2] = USDC;
    }

    function isValidTokenIn(address token) public view virtual override returns (bool) {
        return token == IUSD || token == SIUSD || token == USDC;
    }

    function isValidTokenOut(address token) public view virtual override returns (bool) {
        return token == IUSD || token == SIUSD || token == USDC;
    }

    function assetInfo()
        external
        view
        virtual
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.TOKEN, asset, IERC20Metadata(asset).decimals());
    }
}
