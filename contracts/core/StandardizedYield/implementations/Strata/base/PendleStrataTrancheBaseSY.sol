// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../../../v2/SYBaseUpgV2.sol";
import "../../../../../interfaces/Strata/IStrataTranche.sol";
import "../../../../../interfaces/Strata/IStrataCDO.sol";

abstract contract PendleStrataTrancheBaseSY is SYBaseUpgV2 {
    address public immutable strata;
    bool public immutable isJrt;
    address public immutable baseAsset;
    address public immutable stakedAsset;

    constructor(address _strata, address _baseAsset, address _stakedAsset) SYBaseUpgV2(_strata) {
        strata = _strata;
        baseAsset = _baseAsset;
        stakedAsset = _stakedAsset;

        isJrt = IStrataCDO(IStrataTranche(strata).cdo()).isJrt(strata);
    }

    function initialize(string memory name_, string memory symbol_, address _owner) external virtual initializer {
        __SYBaseUpgV2_init(name_, symbol_, _owner);
        _safeApproveInf(baseAsset, strata);
        _safeApproveInf(stakedAsset, strata);
    }

    function exchangeRate() external view virtual override returns (uint256) {
        return IStrataTranche(strata).convertToAssets(PMath.ONE);
    }

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 amountSharesOut) {
        if (tokenIn == strata) {
            return amountDeposited;
        }
        return IStrataTranche(strata).deposit(tokenIn, amountDeposited, address(this));
    }

    function _redeem(
        address receiver,
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal virtual override returns (uint256) {
        if (tokenOut == strata) {
            _transferOut(strata, receiver, amountSharesToRedeem);
            return amountSharesToRedeem;
        }

        uint256 amountBefore = IERC20Metadata(tokenOut).balanceOf(receiver);
        uint256 amountAssetOut = IStrataTranche(strata).redeem(tokenOut, amountSharesToRedeem, receiver, address(this));

        uint256 amountAfter = IERC20Metadata(tokenOut).balanceOf(receiver);
        require(amountAfter - amountBefore >= amountAssetOut, "SY Strata Tranche: insufficient redeem amount");
        return amountAssetOut;
    }

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == strata) {
            return amountTokenToDeposit;
        }

        return IStrataTranche(strata).previewDeposit(tokenIn, amountTokenToDeposit);
    }

    function _previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal view virtual override returns (uint256 /*amountTokenOut*/) {
        if (tokenOut == strata) {
            return amountSharesToRedeem;
        }

        return IStrataTranche(strata).previewRedeem(tokenOut, amountSharesToRedeem);
    }

    function getTokensIn() public view virtual override returns (address[] memory res) {
        return ArrayLib.create(strata, baseAsset, stakedAsset);
    }

    function getTokensOut() public view virtual override returns (address[] memory res) {
        if (_isStakedAssetValidTokenOut()) return ArrayLib.create(strata, stakedAsset);
        return ArrayLib.create(strata);
    }

    function isValidTokenIn(address token) public view virtual override returns (bool) {
        return token == strata || token == baseAsset || token == stakedAsset;
    }

    function isValidTokenOut(address token) public view virtual override returns (bool) {
        return token == strata || (token == stakedAsset && _isStakedAssetValidTokenOut());
    }

    function assetInfo() external view returns (AssetType assetType, address assetAddress, uint8 assetDecimals) {
        return (AssetType.TOKEN, baseAsset, IERC20Metadata(baseAsset).decimals());
    }

    function _isStakedAssetValidTokenOut() internal view virtual returns (bool);
}
