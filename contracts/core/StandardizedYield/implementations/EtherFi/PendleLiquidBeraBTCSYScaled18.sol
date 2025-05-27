// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.23;

import "../../SYBaseUpg.sol";
import "../../../../interfaces/EtherFi/IVedaTeller.sol";
import "../../../../interfaces/EtherFi/IVedaAccountant.sol";
import "../../../../interfaces/IStandardizedYieldExtended.sol";
import "../../../../interfaces/IPDecimalsWrapperFactory.sol";
import "../../../../interfaces/IPDecimalsWrapper.sol";

contract PendleLiquidBeraBTCSYScaled18 is SYBaseUpg, IStandardizedYieldExtended {
    // solhint-disable immutable-vars-naming
    // solhint-disable const-name-snakecase
    // solhint-disable ordering

    address public constant liquidBeraBTC = 0xC673ef7791724f0dcca38adB47Fbb3AEF3DB6C80;
    address public constant teller = 0xe238e253b67f42ee3aF194BaF7Aba5E2eaddA1B8;

    address public constant EBTC = 0x657e8C867D8B37dCC18fA4Caead9C45EB088C642;
    address public constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address public constant LBTC = 0x8236a87084f8B84306f72007F36F2618A5634494;

    uint256 public constant EXCHANGE_RATE_SCALE = 10 ** 10;
    uint256 public constant ONE_SHARE = 10 ** 8;
    uint256 public constant PREMIUM_SHARE_BPS = 10 ** 4;

    address public immutable wrapper;
    address public immutable rescaledWBTC;
    address public immutable vedaAccountant;

    constructor(
        address _wrapperFactory
    ) SYBaseUpg(IPDecimalsWrapperFactory(_wrapperFactory).getOrCreate(liquidBeraBTC, 18)) {
        wrapper = yieldToken;
        rescaledWBTC = IPDecimalsWrapperFactory(_wrapperFactory).getOrCreate(WBTC, 18);
        vedaAccountant = IVedaTeller(teller).accountant();
    }

    function initialize() external virtual initializer {
        __SYBaseUpg_init("SY ether.fi Liquid Bera BTC scaled18", "SY-liquidBera-BTC-scaled18");
        _safeApproveInf(EBTC, liquidBeraBTC);
        _safeApproveInf(WBTC, liquidBeraBTC);
        _safeApproveInf(LBTC, liquidBeraBTC);
        _safeApproveInf(liquidBeraBTC, yieldToken);
    }

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == wrapper) {
            // POC only, should never use wrapper to deposit
            return amountDeposited;
        }
        if (tokenIn != liquidBeraBTC) {
            (tokenIn, amountDeposited) = (liquidBeraBTC, IVedaTeller(teller).deposit(tokenIn, amountDeposited, 0));
        }
        return IPDecimalsWrapper(wrapper).wrap(amountDeposited);
    }

    function _redeem(
        address receiver,
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal override returns (uint256) {
        if (tokenOut == wrapper) {
            // POC only, should never use wrapper to redeem
            _transferOut(wrapper, receiver, amountSharesToRedeem);
            return amountSharesToRedeem;
        } else {
            uint256 amountOut = IPDecimalsWrapper(wrapper).unwrap(amountSharesToRedeem);
            _transferOut(liquidBeraBTC, receiver, amountOut);
            return amountOut;
        }
    }

    function exchangeRate() public view virtual override(SYBaseUpg, IStandardizedYield) returns (uint256 res) {
        // SY: decimals 18
        // getRateInQuoteSafe: decimals 8
        // wBTC: decimals 8
        return IVedaAccountant(vedaAccountant).getRateInQuoteSafe(WBTC) * EXCHANGE_RATE_SCALE;
    }

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view virtual override returns (uint256 amountSharesOut) {
        if (tokenIn == wrapper) {
            // POC only, should never use wrapper to deposit
            return amountTokenToDeposit;
        }

        uint256 amountLiquidBeraBTC;
        if (tokenIn != liquidBeraBTC) {
            uint256 rate = IVedaAccountant(vedaAccountant).getRateInQuoteSafe(tokenIn);
            amountLiquidBeraBTC = (amountTokenToDeposit * ONE_SHARE) / rate;
            IVedaTeller.Asset memory data = IVedaTeller(teller).assetData(tokenIn);
            amountLiquidBeraBTC = (amountLiquidBeraBTC * (PREMIUM_SHARE_BPS - data.sharePremium)) / PREMIUM_SHARE_BPS;
        } else {
            amountLiquidBeraBTC = amountTokenToDeposit;
        }
        return IPDecimalsWrapper(wrapper).rawToWrapped(amountLiquidBeraBTC);
    }

    function _previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal view virtual override returns (uint256 /*amountTokenOut*/) {
        if (tokenOut == wrapper) {
            // POC only, should never use wrapper to redeem
            return amountSharesToRedeem;
        }
        return IPDecimalsWrapper(wrapper).wrappedToRaw(amountSharesToRedeem);
    }

    function getTokensIn() public view override(SYBaseUpg, IStandardizedYield) returns (address[] memory res) {
        return ArrayLib.create(WBTC, LBTC, EBTC, liquidBeraBTC, wrapper);
    }

    function getTokensOut() public view override(SYBaseUpg, IStandardizedYield) returns (address[] memory res) {
        return ArrayLib.create(liquidBeraBTC, wrapper);
    }

    function isValidTokenIn(address token) public view override(SYBaseUpg, IStandardizedYield) returns (bool) {
        return token == liquidBeraBTC || token == EBTC || token == WBTC || token == LBTC || token == wrapper;
    }

    function isValidTokenOut(address token) public view override(SYBaseUpg, IStandardizedYield) returns (bool) {
        return token == liquidBeraBTC || token == wrapper;
    }

    function assetInfo()
        external
        view
        virtual
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.TOKEN, rescaledWBTC, 18);
    }

    function pricingInfo() external pure returns (address refToken, bool refStrictlyEqual) {
        return (liquidBeraBTC, true);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        require(amount > 0, "transfer zero amount");
    }
}
