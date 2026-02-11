// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../v2/SYBaseUpgV2.sol";
import "../../../interfaces/IERC4626.sol";
import "../../../interfaces/IPDecimalsWrapperFactory.sol";

contract PendleERC4626SYYieldTokenScaled18 is SYBaseUpgV2 {
    address public immutable erc4626;
    address public immutable asset;
    address public immutable assetScaled18;
    uint256 public immutable scaledSharesUnit;
    uint256 public immutable yieldTokenDecimalsOffset;

    constructor(
        address _erc4626,
        address _decimalsWrapperFactory
    ) SYBaseUpgV2(IPDecimalsWrapperFactory(_decimalsWrapperFactory).getOrCreate(_erc4626, 18)) {
        erc4626 = _erc4626;
        asset = IERC4626(_erc4626).asset();

        uint256 vaultDecimals = IERC20Metadata(_erc4626).decimals();
        uint256 assetDecimals = IERC20Metadata(asset).decimals();

        assert(vaultDecimals <= 18);
        assert(assetDecimals <= 18);

        if (assetDecimals < 18) {
            assetScaled18 = IPDecimalsWrapperFactory(_decimalsWrapperFactory).getOrCreate(asset, 18);
        } else {
            assetScaled18 = asset;
        }

        scaledSharesUnit = 10 ** (18 + vaultDecimals - assetDecimals);
        yieldTokenDecimalsOffset = 10 ** (18 - vaultDecimals);
    }

    function initialize(string memory _name, string memory _symbol, address _owner) external virtual initializer {
        __SYBaseUpgV2_init(_name, _symbol, _owner);
        _safeApproveInf(asset, erc4626);
    }

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == erc4626) {
            return amountDeposited * yieldTokenDecimalsOffset;
        } else {
            return IERC4626(erc4626).deposit(amountDeposited, address(this)) * yieldTokenDecimalsOffset;
        }
    }

    function _redeem(
        address receiver,
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal virtual override returns (uint256 amountTokenOut) {
        if (tokenOut == erc4626) {
            amountTokenOut = amountSharesToRedeem / yieldTokenDecimalsOffset;
            _transferOut(erc4626, receiver, amountTokenOut);
        } else {
            amountTokenOut = IERC4626(erc4626).redeem(amountSharesToRedeem / yieldTokenDecimalsOffset, receiver, address(this));
        }
    }

    function exchangeRate() public view virtual override returns (uint256) {
        return IERC4626(erc4626).convertToAssets(scaledSharesUnit);
    }

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == erc4626) return amountTokenToDeposit * yieldTokenDecimalsOffset;
        else return IERC4626(erc4626).previewDeposit(amountTokenToDeposit) * yieldTokenDecimalsOffset;
    }

    function _previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal view virtual override returns (uint256 /*amountTokenOut*/) {
        if (tokenOut == erc4626) return amountSharesToRedeem / yieldTokenDecimalsOffset;
        else return IERC4626(erc4626).previewRedeem(amountSharesToRedeem / yieldTokenDecimalsOffset);
    }

    function getTokensIn() public view virtual override returns (address[] memory res) {
        res = new address[](2);
        res[0] = asset;
        res[1] = erc4626;
    }

    function getTokensOut() public view virtual override returns (address[] memory res) {
        res = new address[](2);
        res[0] = asset;
        res[1] = erc4626;
    }

    function isValidTokenIn(address token) public view virtual override returns (bool) {
        return token == erc4626 || token == asset;
    }

    function isValidTokenOut(address token) public view virtual override returns (bool) {
        return token == erc4626 || token == asset;
    }

    function assetInfo()
        external
        view
        virtual
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.TOKEN, assetScaled18, 18);
    }
}
