// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

abstract contract ScaledTokenMath {
    uint8 public immutable originalDecimals;
    uint8 public immutable scaledDecimals;

    constructor(address _originalToken, address _scaledToken) {
        originalDecimals = IERC20Metadata(_originalToken).decimals();
        scaledDecimals = IERC20Metadata(_scaledToken).decimals();
    }

    function _toScaled(uint256 value) internal view returns (uint256) {
        return value * (10 ** scaledDecimals) / (10 ** originalDecimals);
    }

    function _toOriginal(uint256 value) internal view returns (uint256) {
        return value * (10 ** originalDecimals) / (10 ** scaledDecimals);
    }
}