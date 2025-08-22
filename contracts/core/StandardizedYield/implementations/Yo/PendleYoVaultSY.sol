// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {IERC4626} from "../../../../interfaces/IERC4626.sol";
import {PendleERC4626UpgSYV2} from "../PendleERC4626UpgSYV2.sol";

// __   __    ____            _                  _
// \ \ / /__ |  _ \ _ __ ___ | |_ ___   ___ ___ | |
//  \ V / _ \| |_) | '__/ _ \| __/ _ \ / __/ _ \| |
//   | | (_) |  __/| | | (_) | || (_) | (_| (_) | |
//   |_|\___/|_|   |_|  \___/ \__\___/ \___\___/|_|
/// @title PendleYoVaultSY
/// @notice A Standardized Yield contract for yoVaults.
/// @dev This contract is a wrapper around a yoVault. It allows users to redeem yoTokens for the underlying asset.
/// @dev The underlying asset must be redeemed in Yo.
/// @author https://yo.xyz/
contract PendleYoVaultSY is PendleERC4626UpgSYV2 {
    uint256 public immutable ONE_SHARE;

    constructor(address _yoVault, uint256 _oneShare) PendleERC4626UpgSYV2(_yoVault) {
        asset = IERC4626(_yoVault).asset();
        ONE_SHARE = _oneShare;
    }

    /// @notice Only yoTokens can be redeemed. The underlying asset must be redeemed in Yo.
    function getTokensOut() public view virtual override returns (address[] memory res) {
        res = new address[](1);
        res[0] = yieldToken;
    }

    /// @notice Only yoTokens can be redeemed. The underlying asset must be redeemed in Yo.
    function isValidTokenOut(address token) public view virtual override returns (bool) {
        return token == yieldToken;
    }

    function _previewRedeem(
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal view virtual override returns (uint256 /*amountTokenOut*/) {
        return amountSharesToRedeem;
    }

    function _redeem(
        address receiver,
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal virtual override returns (uint256) {
        _transferOut(yieldToken, receiver, amountSharesToRedeem);
        return amountSharesToRedeem;
    }

    function exchangeRate() public view virtual override returns (uint256) {
        return IERC4626(yieldToken).convertToAssets(ONE_SHARE);
    }
}
