// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../v2/SYBaseUpgV2.sol";
import "../../../interfaces/IPExchangeRateOracle.sol";
import "../../../interfaces/IPDecimalsWrapperFactory.sol";

/// @dev yieldToken and accountingAsset are both scaled to 18 decimals.
/// @dev exchangeRateOracle must quote scaled accountingAsset per scaled yieldToken.
contract PendleERC20WithOracleSY__SelfHarvest is SYBaseUpgV2 {
    using PMath for uint256;

    event YieldCollected(uint256 rate, uint256 amount);

    address public immutable rawYieldToken;
    address public immutable rawAccountingAsset;

    address public immutable accountingAsset;
    address public immutable yieldReceiver;
    address public immutable exchangeRateOracle;

    uint256 public immutable yieldTokenDecimalsOffset;

    uint256 internal _watermarkRateStored;
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

    function initialize(string memory _name, string memory _symbol, address _owner) external virtual initializer {
        __SYBaseUpgV2_init(_name, _symbol, _owner);
    }

    function _deposit(
        address /*tokenIn*/,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 amountSharesOut) {
        (, uint256 watermarkRate) = updateRates();
        amountSharesOut = (amountDeposited * yieldTokenDecimalsOffset).mulDown(watermarkRate);
    }

    function _redeem(
        address receiver,
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal virtual override returns (uint256 amountTokenOut) {
        (, uint256 watermarkRate) = updateRates();
        amountTokenOut = amountSharesToRedeem.divDown(watermarkRate) / yieldTokenDecimalsOffset;
        _transferOut(rawYieldToken, receiver, amountTokenOut);
    }

    function collectUnderlyingYield() external virtual onlyOwner returns (uint256 collectedYield) {
        (uint256 currentRate, uint256 watermarkRate) = updateRates();

        uint256 rawYieldTokenBacking = PMath.rawDivUp(
            PMath.rawDivUp(totalSupply() * PMath.ONE, watermarkRate),
            yieldTokenDecimalsOffset
        );
        uint256 rawYieldTokenOwned = _selfBalance(rawYieldToken);

        if (rawYieldTokenOwned > rawYieldTokenBacking) {
            collectedYield = rawYieldTokenOwned - rawYieldTokenBacking;
            _transferOut(rawYieldToken, yieldReceiver, collectedYield);
            emit YieldCollected(currentRate, collectedYield);
        }
    }

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

    function _previewDeposit(
        address /*tokenIn*/,
        uint256 amountTokenToDeposit
    ) internal view virtual override returns (uint256 amountSharesOut) {
        (, uint256 watermarkRate) = getRates();
        amountSharesOut = (amountTokenToDeposit * yieldTokenDecimalsOffset).mulDown(watermarkRate);
    }

    function _previewRedeem(
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal view virtual override returns (uint256 amountTokenOut) {
        (, uint256 watermarkRate) = getRates();
        amountTokenOut = amountSharesToRedeem.divDown(watermarkRate) / yieldTokenDecimalsOffset;
    }

    function getTokensIn() public view virtual override returns (address[] memory res) {
        return ArrayLib.create(rawYieldToken);
    }

    function getTokensOut() public view virtual override returns (address[] memory res) {
        return ArrayLib.create(rawYieldToken);
    }

    function isValidTokenIn(address token) public view virtual override returns (bool) {
        return token == rawYieldToken;
    }

    function isValidTokenOut(address token) public view virtual override returns (bool) {
        return token == rawYieldToken;
    }

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
}
