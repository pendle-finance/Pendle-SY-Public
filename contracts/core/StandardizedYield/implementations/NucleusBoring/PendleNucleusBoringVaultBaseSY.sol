// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../v2/SYBaseUpgV2.sol";
import "../../../../interfaces/NucleusBoring/INucleusBoringTeller.sol";
import "../../../../interfaces/NucleusBoring/INucleusBoringDepositor.sol";
import "../../../../interfaces/NucleusBoring/INucleusBoringAccountant.sol";

abstract contract PendleNucleusBoringVaultBaseSY is SYBaseUpgV2 {
    uint256 public immutable ONE_SHARE;
    address public immutable underlyingAsset;
    address public immutable communityDepositor;
    address public immutable boringTeller;
    address public immutable accountant;

    uint256[100] private __gap;

    constructor(
        address _boringVault,
        address _boringTeller,
        address _depositor,
        address _underlyingAsset
    ) SYBaseUpgV2(_boringVault) {
        communityDepositor = _depositor;
        boringTeller = _boringTeller;
        accountant = INucleusBoringTeller(boringTeller).accountant();
        underlyingAsset = _underlyingAsset;
        ONE_SHARE = 10 ** IERC20Metadata(_boringVault).decimals();
    }

    function PENDLE_COMMUNITY_CODE() internal pure virtual returns (bytes memory);

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 amountSharesOut) {
        if (tokenIn == yieldToken) {
            return amountDeposited;
        }

        amountSharesOut = INucleusBoringDepositor(communityDepositor).deposit(
            tokenIn,
            amountDeposited,
            0,
            address(this),
            PENDLE_COMMUNITY_CODE()
        );
    }

    function _redeem(
        address receiver,
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal virtual override returns (uint256 /*amountTokenOut*/) {
        _transferOut(yieldToken, receiver, amountSharesToRedeem);
        return amountSharesToRedeem;
    }

    function exchangeRate() external view virtual override returns (uint256 res) {
        return (INucleusBoringAccountant(accountant).getRateInQuoteSafe(underlyingAsset) * PMath.ONE) / ONE_SHARE;
    }

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view virtual override returns (uint256 amountSharesOut) {
        if (tokenIn == yieldToken) {
            return amountTokenToDeposit;
        }

        uint256 rate = INucleusBoringAccountant(accountant).getRateInQuoteSafe(tokenIn);
        amountSharesOut = (amountTokenToDeposit * ONE_SHARE) / rate;
    }

    function _previewRedeem(
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal view virtual override returns (uint256 /*amountTokenOut*/) {
        return amountSharesToRedeem;
    }

    function getTokensOut() public view virtual override returns (address[] memory res) {
        return ArrayLib.create(yieldToken);
    }

    function isValidTokenOut(address token) public view virtual override returns (bool) {
        return token == yieldToken;
    }

    function assetInfo() external view returns (AssetType assetType, address assetAddress, uint8 assetDecimals) {
        return (AssetType.TOKEN, underlyingAsset, IERC20Metadata(underlyingAsset).decimals());
    }
}
