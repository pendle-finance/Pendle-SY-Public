// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../../v2/SYBaseUpgV2.sol";
import "../../../misc/TokenWithSupplyCapUpg.sol";
import "../../../../interfaces/IPExchangeRateOracle.sol";
import "../../../../interfaces/IPDecimalsWrapperFactory.sol";

/// @dev yieldToken is tokenizedStock scaled to 18 decimals.
/// @dev exchangeRateOracle must quote the issuer multiplier of tokenizedStock, in 18 decimals.
contract PendleTokenizedStocksMultiplierSY is SYBaseUpgV2, TokenWithSupplyCapUpg {
    event RateBoundsUpdated(uint256 minRate, uint256 maxRate);

    address public immutable tokenizedStock;
    address public immutable exchangeRateOracle;
    uint256 public immutable decimalsOffset;

    uint256 public minRate;
    uint256 public maxRate;
    uint256[100] private __gap;

    constructor(
        address _tokenizedStock,
        address _exchangeRateOracle,
        address _decimalsWrapperFactory
    ) SYBaseUpgV2(_scaleToken(_decimalsWrapperFactory, _tokenizedStock)) {
        assert(IERC20Metadata(_tokenizedStock).decimals() <= 18);

        tokenizedStock = _tokenizedStock;
        exchangeRateOracle = _exchangeRateOracle;
        decimalsOffset = 10 ** (18 - IERC20Metadata(_tokenizedStock).decimals());
    }

    function _scaleToken(address _decimalsWrapperFactory, address _token) private returns (address scaledToken) {
        scaledToken = IERC20Metadata(_token).decimals() == 18
            ? _token
            : IPDecimalsWrapperFactory(_decimalsWrapperFactory).getOrCreate(_token, 18);
    }

    function initialize(string memory _name, string memory _symbol, address _owner) external virtual initializer {
        __SYBaseUpgV2_init(_name, _symbol, _owner);
        __tokenWithSupplyCap_init(type(uint256).max);
        _setRateBounds(0, type(uint256).max);
    }

    /*///////////////////////////////////////////////////////////////
                               DEPOSIT / REDEEM
    //////////////////////////////////////////////////////////////*/

    function _deposit(
        address /*tokenIn*/,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 /*amountSharesOut*/) {
        return amountDeposited * decimalsOffset;
    }

    function _redeem(
        address receiver,
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal virtual override returns (uint256 amountTokenOut) {
        amountTokenOut = amountSharesToRedeem / decimalsOffset;
        _transferOut(tokenizedStock, receiver, amountTokenOut);
    }

    /*///////////////////////////////////////////////////////////////
                               RATES
    //////////////////////////////////////////////////////////////*/

    function exchangeRate() public view virtual override returns (uint256 rate) {
        rate = IPExchangeRateOracle(exchangeRateOracle).getExchangeRate();
        require(rate >= minRate && rate <= maxRate, "rate out of range");
    }

    function setRateBounds(uint256 _minRate, uint256 _maxRate) external onlyOwner {
        _setRateBounds(_minRate, _maxRate);
    }

    function _setRateBounds(uint256 _minRate, uint256 _maxRate) internal {
        require(_minRate <= _maxRate, "invalid bounds");
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
    ) internal view virtual override returns (uint256 /*amountSharesOut*/) {
        return amountTokenToDeposit * decimalsOffset;
    }

    function _previewRedeem(
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal view virtual override returns (uint256 /*amountTokenOut*/) {
        return amountSharesToRedeem / decimalsOffset;
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
        return (tokenizedStock, true);
    }

    function assetInfo()
        external
        view
        virtual
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.LIQUIDITY, yieldToken, 18);
    }

    /*///////////////////////////////////////////////////////////////
                               SUPPLY CAP
    //////////////////////////////////////////////////////////////*/

    function getAbsoluteTotalSupply() external view returns (uint256) {
        return totalSupply();
    }

    function _afterTokenTransfer(address from, address, uint256) internal view override {
        if (from != address(0)) {
            return;
        }
        _checkSupplyCap(totalSupply());
    }
}
