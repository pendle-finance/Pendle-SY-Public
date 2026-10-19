// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../v2/SYBaseUpgV2.sol";
import {IPDecimalsWrapperFactory} from "../../../interfaces/IPDecimalsWrapperFactory.sol";
import {IPExchangeRateOracle} from "../../../interfaces/IPExchangeRateOracle.sol";
import {MerklRewardAbstract__NoStorage} from "../../misc/MerklRewardAbstract__NoStorage.sol";
import {TokenWithSupplyCapUpg} from "../../misc/TokenWithSupplyCapUpg.sol";

contract PendleERC20WithOracleSYScaled18 is SYBaseUpgV2, TokenWithSupplyCapUpg, MerklRewardAbstract__NoStorage {
    address public immutable rawYieldToken;
    address public immutable underlyingAsset;
    address public immutable underlyingAssetScaled18;
    address public immutable exchangeRateOracle;
    uint256 public immutable yieldTokenDecimalsOffset;

    uint256[100] private __gap;

    constructor(
        address _rawYieldToken,
        address _underlyingAsset,
        address _exchangeRateOracle,
        address _decimalsWrapperFactory,
        address _offchainRewardManager
    )
        SYBaseUpgV2(_scaleToken(_decimalsWrapperFactory, _rawYieldToken))
        MerklRewardAbstract__NoStorage(_offchainRewardManager)
    {
        rawYieldToken = _rawYieldToken;
        underlyingAsset = _underlyingAsset;
        exchangeRateOracle = _exchangeRateOracle;

        uint256 rawYieldTokenDecimals = IERC20Metadata(_rawYieldToken).decimals();
        uint256 assetDecimals = IERC20Metadata(_underlyingAsset).decimals();

        assert(rawYieldTokenDecimals <= 18);
        assert(assetDecimals <= 18);

        underlyingAssetScaled18 = _scaleToken(_decimalsWrapperFactory, _underlyingAsset);
        yieldTokenDecimalsOffset = 10 ** (18 - rawYieldTokenDecimals);
    }

    function _scaleToken(address _decimalsWrapperFactory, address _token) private returns (address scaledToken) {
        scaledToken = IERC20Metadata(_token).decimals() == 18
            ? _token
            : IPDecimalsWrapperFactory(_decimalsWrapperFactory).getOrCreate(_token, 18);
    }

    function initialize(string memory _name, string memory _symbol, address _owner) external virtual initializer {
        __SYBaseUpgV2_init(_name, _symbol, _owner);
        __tokenWithSupplyCap_init(type(uint256).max);
    }

    // ==== DEPOSIT / REDEEM ====

    function _deposit(
        address,
        uint256 amountDeposited
    ) internal view virtual override returns (uint256 /*amountSharesOut*/) {
        return amountDeposited * yieldTokenDecimalsOffset;
    }

    function _redeem(
        address receiver,
        address,
        uint256 amountSharesToRedeem
    ) internal virtual override returns (uint256 amountTokenOut) {
        amountTokenOut = amountSharesToRedeem / yieldTokenDecimalsOffset;
        _transferOut(rawYieldToken, receiver, amountTokenOut);
    }

    // ==== EXCHANGE RATE ====

    /// @dev oracle must return rawYieldToken scaled18 -> underlyingAsset scaled18, 18 decimals
    function exchangeRate() public view virtual override returns (uint256) {
        return IPExchangeRateOracle(exchangeRateOracle).getExchangeRate();
    }

    // ==== PREVIEW ====

    function _previewDeposit(
        address,
        uint256 amountTokenToDeposit
    ) internal view virtual override returns (uint256 /*amountSharesOut*/) {
        return amountTokenToDeposit * yieldTokenDecimalsOffset;
    }

    function _previewRedeem(
        address,
        uint256 amountSharesToRedeem
    ) internal view virtual override returns (uint256 /*amountTokenOut*/) {
        return amountSharesToRedeem / yieldTokenDecimalsOffset;
    }

    // ==== TOKENS IN / OUT ====

    function getTokensIn() public view virtual override returns (address[] memory) {
        return ArrayLib.create(rawYieldToken);
    }

    function getTokensOut() public view virtual override returns (address[] memory) {
        return ArrayLib.create(rawYieldToken);
    }

    function isValidTokenIn(address token) public view virtual override returns (bool) {
        return token == rawYieldToken;
    }

    function isValidTokenOut(address token) public view virtual override returns (bool) {
        return token == rawYieldToken;
    }

    // ==== METADATA ====

    function assetInfo() external view virtual returns (AssetType, address, uint8) {
        return (AssetType.TOKEN, underlyingAssetScaled18, 18);
    }

    function pricingInfo() external view virtual override returns (address refToken, bool refStrictlyEqual) {
        return (rawYieldToken, true);
    }

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
