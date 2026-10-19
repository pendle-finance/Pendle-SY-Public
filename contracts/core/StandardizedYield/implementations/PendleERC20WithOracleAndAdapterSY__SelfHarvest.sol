// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../v2/SYBaseUpgV2.sol";
import "../../../interfaces/IPExchangeRateOracle.sol";
import "../../../interfaces/IPDecimalsWrapperFactory.sol";
import "../../../interfaces/IStandardizedYieldAdapter.sol";
import "../../../interfaces/IPStandardizedYieldWithAdapter.sol";
import "../../misc/TokenWithSupplyCapUpg.sol";

/// @dev yieldToken and accountingAsset are both scaled to 18 decimals.
/// @dev exchangeRateOracle must quote scaled accountingAsset per scaled yieldToken.
contract PendleERC20WithOracleAndAdapterSY__SelfHarvest is
    SYBaseUpgV2,
    TokenWithSupplyCapUpg,
    IPStandardizedYieldWithAdapter
{
    using PMath for uint256;
    using ArrayLib for address[];

    event YieldCollected(uint256 rate, uint256 amount);

    address public immutable rawYieldToken;
    address public immutable rawAccountingAsset;

    address public immutable accountingAsset;
    address public immutable yieldReceiver;
    address public immutable exchangeRateOracle;

    uint256 public immutable yieldTokenDecimalsOffset;

    uint256 internal _watermarkRateStored;
    address public adapter;
    uint256[100] private __gap;

    constructor(
        address _rawYieldToken,
        address _rawAccountingAsset,
        address _exchangeRateOracle,
        address _yieldReceiver,
        address _decimalsWrapperFactory
    ) SYBaseUpgV2(_scaleToken(_decimalsWrapperFactory, _rawYieldToken)) {
        assert(IERC20Metadata(_rawYieldToken).decimals() <= 18);
        assert(IERC20Metadata(_rawAccountingAsset).decimals() <= 18);

        rawYieldToken = _rawYieldToken;
        yieldTokenDecimalsOffset = 10 ** (18 - IERC20Metadata(_rawYieldToken).decimals());

        rawAccountingAsset = _rawAccountingAsset;
        accountingAsset = _scaleToken(_decimalsWrapperFactory, _rawAccountingAsset);

        exchangeRateOracle = _exchangeRateOracle;
        yieldReceiver = _yieldReceiver;
    }

    function _scaleToken(address _decimalsWrapperFactory, address _token) private returns (address scaledToken) {
        scaledToken = IERC20Metadata(_token).decimals() == 18
            ? _token
            : IPDecimalsWrapperFactory(_decimalsWrapperFactory).getOrCreate(_token, 18);
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        address _adapter,
        address _owner
    ) external virtual initializer {
        __SYBaseUpgV2_init(_name, _symbol, _owner);
        __tokenWithSupplyCap_init(type(uint256).max);
        _setAdapter(_adapter);
    }

    // ==== ADAPTER ====

    function setAdapter(address _adapter) external virtual override onlyOwner {
        _setAdapter(_adapter);
    }

    function _setAdapter(address _adapter) internal {
        require(
            _adapter == address(0) || IStandardizedYieldAdapter(_adapter).PIVOT_TOKEN() == rawYieldToken,
            "invalid adapter"
        );
        adapter = _adapter;
        emit SetAdapter(_adapter);
    }

    // ==== DEPOSIT / REDEEM ====

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 amountSharesOut) {
        uint256 amountRaw = amountDeposited;
        if (tokenIn != rawYieldToken) {
            uint256 rawYieldTokenBalanceBefore = _selfBalance(rawYieldToken);
            _transferOut(tokenIn, adapter, amountDeposited);
            amountRaw = IStandardizedYieldAdapter(adapter).convertToDeposit(tokenIn, amountDeposited);
            require(_selfBalance(rawYieldToken) >= rawYieldTokenBalanceBefore + amountRaw, "adapter under-delivered");
        }

        (, uint256 watermarkRate) = updateRates();
        amountSharesOut = (amountRaw * yieldTokenDecimalsOffset).mulDown(watermarkRate);

        require(
            _selfBalance(rawYieldToken) >= _rawYieldTokenBacking(totalSupply() + amountSharesOut, watermarkRate),
            "insufficient shares"
        );
    }

    function _redeem(
        address receiver,
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal virtual override returns (uint256 amountTokenOut) {
        (, uint256 watermarkRate) = updateRates();
        uint256 amountRaw = amountSharesToRedeem.divDown(watermarkRate) / yieldTokenDecimalsOffset;

        if (tokenOut == rawYieldToken) {
            amountTokenOut = amountRaw;
            _transferOut(rawYieldToken, receiver, amountTokenOut);
        } else {
            _transferOut(rawYieldToken, adapter, amountRaw);
            amountTokenOut = IStandardizedYieldAdapter(adapter).convertToRedeem(tokenOut, amountRaw);
            _transferOut(tokenOut, receiver, amountTokenOut);
        }
    }

    // ==== YIELD ====

    function collectUnderlyingYield() external virtual onlyOwner returns (uint256 collectedYield) {
        (uint256 currentRate, uint256 watermarkRate) = updateRates();

        uint256 rawYieldTokenBacking = _rawYieldTokenBacking(totalSupply(), watermarkRate);
        uint256 rawYieldTokenOwned = _selfBalance(rawYieldToken);

        if (rawYieldTokenOwned > rawYieldTokenBacking) {
            collectedYield = rawYieldTokenOwned - rawYieldTokenBacking;
            _transferOut(rawYieldToken, yieldReceiver, collectedYield);
            emit YieldCollected(currentRate, collectedYield);
        }
    }

    function _rawYieldTokenBacking(uint256 supply, uint256 watermarkRate) internal view returns (uint256) {
        return PMath.rawDivUp(PMath.rawDivUp(supply * PMath.ONE, watermarkRate), yieldTokenDecimalsOffset);
    }

    // ==== EXCHANGE RATE ====

    function getRates() public view virtual returns (uint256 currentRate, uint256 watermarkRate) {
        currentRate = IPExchangeRateOracle(exchangeRateOracle).getExchangeRate();
        watermarkRate = PMath.max(_watermarkRateStored, currentRate);
    }

    function updateRates() public virtual returns (uint256 currentRate, uint256 watermarkRate) {
        (currentRate, watermarkRate) = getRates();
        _watermarkRateStored = watermarkRate;
    }

    function exchangeRate() external view virtual override returns (uint256) {
        (uint256 currentRate, uint256 watermarkRate) = getRates();
        return currentRate.divDown(watermarkRate);
    }

    // ==== PREVIEW ====

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view virtual override returns (uint256 amountSharesOut) {
        if (tokenIn != rawYieldToken) {
            amountTokenToDeposit = IStandardizedYieldAdapter(adapter).previewConvertToDeposit(
                tokenIn,
                amountTokenToDeposit
            );
        }
        (, uint256 watermarkRate) = getRates();
        amountSharesOut = (amountTokenToDeposit * yieldTokenDecimalsOffset).mulDown(watermarkRate);
    }

    function _previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal view virtual override returns (uint256 amountTokenOut) {
        (, uint256 watermarkRate) = getRates();
        uint256 amountRaw = amountSharesToRedeem.divDown(watermarkRate) / yieldTokenDecimalsOffset;
        if (tokenOut == rawYieldToken) {
            return amountRaw;
        }
        return IStandardizedYieldAdapter(adapter).previewConvertToRedeem(tokenOut, amountRaw);
    }

    // ==== TOKENS IN / OUT ====

    function getTokensIn() public view virtual override returns (address[] memory res) {
        if (adapter == address(0)) {
            return ArrayLib.create(rawYieldToken);
        }
        return IStandardizedYieldAdapter(adapter).getAdapterTokensDeposit().append(rawYieldToken);
    }

    function getTokensOut() public view virtual override returns (address[] memory res) {
        if (adapter == address(0)) {
            return ArrayLib.create(rawYieldToken);
        }
        return IStandardizedYieldAdapter(adapter).getAdapterTokensRedeem().append(rawYieldToken);
    }

    function isValidTokenIn(address token) public view virtual override returns (bool) {
        if (token == rawYieldToken) {
            return true;
        }
        return adapter != address(0) && IStandardizedYieldAdapter(adapter).getAdapterTokensDeposit().contains(token);
    }

    function isValidTokenOut(address token) public view virtual override returns (bool) {
        if (token == rawYieldToken) {
            return true;
        }
        return adapter != address(0) && IStandardizedYieldAdapter(adapter).getAdapterTokensRedeem().contains(token);
    }

    // ==== METADATA ====

    function pricingInfo() external view virtual override returns (address refToken, bool refStrictlyEqual) {
        return (rawAccountingAsset, false);
    }

    function assetInfo()
        external
        view
        virtual
        override
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.TOKEN, accountingAsset, 18);
    }

    // ==== SUPPLY CAP ====

    function getAbsoluteTotalSupply() external view virtual override returns (uint256) {
        return totalSupply();
    }

    function _afterTokenTransfer(address from, address, uint256) internal view override {
        if (from != address(0)) {
            return;
        }
        _checkSupplyCap(totalSupply());
    }
}
