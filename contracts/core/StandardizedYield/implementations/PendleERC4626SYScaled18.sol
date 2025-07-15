// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../v2/SYBaseUpgV2.sol";
import "../../../interfaces/IERC4626.sol";
import "../../../interfaces/IPDecimalsWrapperFactory.sol";
import "../../../interfaces/IPTokenWithSupplyCap.sol";

contract PendleERC4626SYScaled18 is SYBaseUpgV2, IPTokenWithSupplyCap {
    using PMath for uint256;

    address public immutable asset;
    address public immutable assetScaled18;
    uint256 public immutable decimalsOffset;

    constructor(address _erc4626, address _decimalsWrapperFactory) SYBaseUpgV2(_erc4626) {
        asset = IERC4626(_erc4626).asset();
        assetScaled18 = IPDecimalsWrapperFactory(_decimalsWrapperFactory).getOrCreate(asset, 18);
        decimalsOffset = 10 ** (18 - IERC20Metadata(asset).decimals());
    }

    function initialize(string memory _name, string memory _symbol, address _owner) external virtual initializer {
        __SYBaseUpgV2_init(_name, _symbol, _owner);
        _safeApproveInf(asset, yieldToken);
    }

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == yieldToken) {
            return amountDeposited;
        } else {
            return IERC4626(yieldToken).deposit(amountDeposited, address(this));
        }
    }

    function _redeem(
        address receiver,
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal virtual override returns (uint256 amountTokenOut) {
        if (tokenOut == yieldToken) {
            amountTokenOut = amountSharesToRedeem;
            _transferOut(yieldToken, receiver, amountTokenOut);
        } else {
            amountTokenOut = IERC4626(yieldToken).redeem(amountSharesToRedeem, receiver, address(this));
        }
    }

    function exchangeRate() public view virtual override returns (uint256) {
        return IERC4626(yieldToken).convertToAssets(PMath.ONE * decimalsOffset);
    }

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == yieldToken) return amountTokenToDeposit;
        else return IERC4626(yieldToken).previewDeposit(amountTokenToDeposit);
    }

    function _previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal view virtual override returns (uint256 /*amountTokenOut*/) {
        if (tokenOut == yieldToken) return amountSharesToRedeem;
        else return IERC4626(yieldToken).previewRedeem(amountSharesToRedeem);
    }

    function getTokensIn() public view virtual override returns (address[] memory res) {
        res = new address[](2);
        res[0] = asset;
        res[1] = yieldToken;
    }

    function getTokensOut() public view virtual override returns (address[] memory res) {
        res = new address[](2);
        res[0] = asset;
        res[1] = yieldToken;
    }

    function isValidTokenIn(address token) public view virtual override returns (bool) {
        return token == yieldToken || token == asset;
    }

    function isValidTokenOut(address token) public view virtual override returns (bool) {
        return token == yieldToken || token == asset;
    }

    function assetInfo()
        external
        view
        virtual
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.TOKEN, assetScaled18, 18);
    }

    function getAbsoluteSupplyCap() external view returns (uint256) {
        return IERC4626(yieldToken).totalSupply() + IERC4626(yieldToken).maxMint(address(this));
    }

    function getAbsoluteTotalSupply() external view returns (uint256) {
        return IERC4626(yieldToken).totalSupply();
    }
}
