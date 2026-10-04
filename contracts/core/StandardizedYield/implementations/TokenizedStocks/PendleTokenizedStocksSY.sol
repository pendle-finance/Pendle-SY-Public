// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../../v2/SYBaseUpgV2.sol";
import "../../../../interfaces/IPExchangeRateOracle.sol";
import "../../../../interfaces/IPDecimalsWrapperFactory.sol";

/// @dev yieldToken is tokenizedStock scaled to 18 decimals.
/// @dev exchangeRateOracle must quote underlying shares per scaled yieldToken, in 18 decimals.
/// @dev shareToken is a non-transferable, zero-supply accounting unit used only for metadata and pricing.
///      It does not represent, wrap, or confer any claim on the underlying security. The SY holds only tokenizedStock.
contract PendleTokenizedStocksSY is SYBaseUpgV2 {
    using PMath for uint256;

    event YieldCollected(uint256 currentRate, uint256 watermarkRate, uint256 collectedYield);
    event RateBoundsUpdated(uint256 minRate, uint256 maxRate);

    address public immutable tokenizedStock;
    address public immutable shareToken;
    address public immutable yieldReceiver;
    address public immutable exchangeRateOracle;

    uint256 public immutable decimalsOffset;

    uint256 internal _watermarkRateStored;
    uint256 public minRate;
    uint256 public maxRate;
    uint256[100] private __gap;

    constructor(
        address _tokenizedStock,
        address _shareToken,
        address _exchangeRateOracle,
        address _yieldReceiver,
        address _decimalsWrapperFactory
    ) SYBaseUpgV2(_scaleToken(_decimalsWrapperFactory, _tokenizedStock)) {
        assert(IERC20Metadata(_tokenizedStock).decimals() <= 18);
        assert(IERC20Metadata(_shareToken).decimals() == 18);

        tokenizedStock = _tokenizedStock;
        shareToken = _shareToken;
        decimalsOffset = 10 ** (18 - IERC20Metadata(_tokenizedStock).decimals());

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
        _setRateBounds(0, type(uint256).max);
    }

    /*///////////////////////////////////////////////////////////////
                               DEPOSIT / REDEEM
    //////////////////////////////////////////////////////////////*/

    function _deposit(
        address /*tokenIn*/,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 amountSharesOut) {
        (, uint256 watermarkRate) = updateRates();
        amountSharesOut = (amountDeposited * decimalsOffset).mulDown(watermarkRate);
    }

    function _redeem(
        address receiver,
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal virtual override returns (uint256 amountTokenOut) {
        (, uint256 watermarkRate) = updateRates();
        amountTokenOut = amountSharesToRedeem.divDown(watermarkRate) / decimalsOffset;
        _transferOut(tokenizedStock, receiver, amountTokenOut);
    }

    /*///////////////////////////////////////////////////////////////
                               YIELD COLLECTION
    //////////////////////////////////////////////////////////////*/

    function collectUnderlyingYield() external virtual onlyOwner returns (uint256 collectedYield) {
        (uint256 currentRate, uint256 watermarkRate) = updateRates();

        uint256 tokenizedStockBacking = PMath.rawDivUp(
            PMath.rawDivUp(totalSupply() * PMath.ONE, watermarkRate),
            decimalsOffset
        );
        uint256 tokenizedStockOwned = _selfBalance(tokenizedStock);

        if (tokenizedStockOwned > tokenizedStockBacking) {
            collectedYield = tokenizedStockOwned - tokenizedStockBacking;
            _transferOut(tokenizedStock, yieldReceiver, collectedYield);
            emit YieldCollected(currentRate, watermarkRate, collectedYield);
        }
    }

    /*///////////////////////////////////////////////////////////////
                               RATES
    //////////////////////////////////////////////////////////////*/

    function getRates() public view virtual returns (uint256 currentRate, uint256 watermarkRate) {
        currentRate = IPExchangeRateOracle(exchangeRateOracle).getExchangeRate();
        require(currentRate >= minRate && currentRate <= maxRate, "PTSSY: rate out of range");
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

    function setRateBounds(uint256 _minRate, uint256 _maxRate) external onlyOwner {
        _setRateBounds(_minRate, _maxRate);
    }

    function _setRateBounds(uint256 _minRate, uint256 _maxRate) internal {
        require(_minRate <= _maxRate, "PTSSY: invalid bounds");
        minRate = _minRate;
        maxRate = _maxRate;
        emit RateBoundsUpdated(_minRate, _maxRate);
    }

    /*///////////////////////////////////////////////////////////////
                               PREVIEW
    //////////////////////////////////////////////////////////////*/

    function _previewDeposit(
        address /*tokenIn*/,
        uint256 amountTokenToDeposit
    ) internal view virtual override returns (uint256 amountSharesOut) {
        (, uint256 watermarkRate) = getRates();
        amountSharesOut = (amountTokenToDeposit * decimalsOffset).mulDown(watermarkRate);
    }

    function _previewRedeem(
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal view virtual override returns (uint256 amountTokenOut) {
        (, uint256 watermarkRate) = getRates();
        amountTokenOut = amountSharesToRedeem.divDown(watermarkRate) / decimalsOffset;
    }

    /*///////////////////////////////////////////////////////////////
                               TOKENS
    //////////////////////////////////////////////////////////////*/

    function getTokensIn() public view virtual override returns (address[] memory res) {
        return ArrayLib.create(tokenizedStock);
    }

    function getTokensOut() public view virtual override returns (address[] memory res) {
        return ArrayLib.create(tokenizedStock);
    }

    function isValidTokenIn(address token) public view virtual override returns (bool) {
        return token == tokenizedStock;
    }

    function isValidTokenOut(address token) public view virtual override returns (bool) {
        return token == tokenizedStock;
    }

    /*///////////////////////////////////////////////////////////////
                               METADATA
    //////////////////////////////////////////////////////////////*/

    function pricingInfo() external view virtual override returns (address refToken, bool refStrictlyEqual) {
        return (shareToken, false);
    }

    function assetInfo()
        external
        view
        virtual
        override
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.TOKEN, shareToken, 18);
    }
}
