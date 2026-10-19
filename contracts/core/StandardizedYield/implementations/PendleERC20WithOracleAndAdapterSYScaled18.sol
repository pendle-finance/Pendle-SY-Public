// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../v2/SYBaseUpgV2.sol";
import {IPDecimalsWrapperFactory} from "../../../interfaces/IPDecimalsWrapperFactory.sol";
import {IPExchangeRateOracle} from "../../../interfaces/IPExchangeRateOracle.sol";
import {IStandardizedYieldAdapter} from "../../../interfaces/IStandardizedYieldAdapter.sol";
import {IPStandardizedYieldWithAdapter} from "../../../interfaces/IPStandardizedYieldWithAdapter.sol";
import {MerklRewardAbstract__NoStorage} from "../../misc/MerklRewardAbstract__NoStorage.sol";
import {TokenWithSupplyCapUpg} from "../../misc/TokenWithSupplyCapUpg.sol";

contract PendleERC20WithOracleAndAdapterSYScaled18 is
    SYBaseUpgV2,
    TokenWithSupplyCapUpg,
    MerklRewardAbstract__NoStorage,
    IPStandardizedYieldWithAdapter
{
    using ArrayLib for address[];

    address public immutable rawYieldToken;
    address public immutable underlyingAsset;
    address public immutable underlyingAssetScaled18;
    address public immutable exchangeRateOracle;
    uint256 public immutable yieldTokenDecimalsOffset;

    address public adapter;
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
        amountSharesOut = amountRaw * yieldTokenDecimalsOffset;

        require(
            _selfBalance(rawYieldToken) * yieldTokenDecimalsOffset >= totalSupply() + amountSharesOut,
            "insufficient shares"
        );
    }

    function _redeem(
        address receiver,
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal virtual override returns (uint256 amountTokenOut) {
        uint256 amountRaw = amountSharesToRedeem / yieldTokenDecimalsOffset;
        if (tokenOut == rawYieldToken) {
            amountTokenOut = amountRaw;
            _transferOut(rawYieldToken, receiver, amountTokenOut);
        } else {
            _transferOut(rawYieldToken, adapter, amountRaw);
            amountTokenOut = IStandardizedYieldAdapter(adapter).convertToRedeem(tokenOut, amountRaw);
            _transferOut(tokenOut, receiver, amountTokenOut);
        }
    }

    // ==== EXCHANGE RATE ====

    /// @dev oracle must return rawYieldToken scaled18 -> underlyingAsset scaled18, 18 decimals
    function exchangeRate() public view virtual override returns (uint256) {
        return IPExchangeRateOracle(exchangeRateOracle).getExchangeRate();
    }

    // ==== PREVIEW ====

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn != rawYieldToken) {
            amountTokenToDeposit = IStandardizedYieldAdapter(adapter).previewConvertToDeposit(
                tokenIn,
                amountTokenToDeposit
            );
        }
        return amountTokenToDeposit * yieldTokenDecimalsOffset;
    }

    function _previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal view virtual override returns (uint256 /*amountTokenOut*/) {
        uint256 amountRaw = amountSharesToRedeem / yieldTokenDecimalsOffset;
        if (tokenOut == rawYieldToken) {
            return amountRaw;
        }
        return IStandardizedYieldAdapter(adapter).previewConvertToRedeem(tokenOut, amountRaw);
    }

    // ==== TOKENS IN / OUT ====

    function getTokensIn() public view virtual override returns (address[] memory) {
        if (adapter == address(0)) {
            return ArrayLib.create(rawYieldToken);
        }
        return IStandardizedYieldAdapter(adapter).getAdapterTokensDeposit().append(rawYieldToken);
    }

    function getTokensOut() public view virtual override returns (address[] memory) {
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
