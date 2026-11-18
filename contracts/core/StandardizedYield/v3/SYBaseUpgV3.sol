// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../v2/SYBaseUpgV2.sol";
import "../../misc/TokenWithSupplyCap.sol";

abstract contract SYBaseUpgV3 is SYBaseUpgV2, TokenWithSupplyCap {
    uint256[100] private __gap;

    constructor(address _yieldToken) SYBaseUpgV2(_yieldToken) {}

    function __SYBaseUpgV3_init(string memory name_, string memory symbol_, address _owner) internal onlyInitializing {
        __SYBaseUpgV2_init(name_, symbol_, _owner);
        _updateSupplyCap(type(uint256).max);
    }

    function updateSupplyCap(uint256 newSupplyCap) external onlyOwner {
        _updateSupplyCap(newSupplyCap);
    }

    function previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) external view virtual override returns (uint256 amountSharesOut) {
        if (!isValidTokenIn(tokenIn)) revert Errors.SYInvalidTokenIn(tokenIn);
        amountSharesOut = _previewDeposit(tokenIn, amountTokenToDeposit);
        _checkSupplyCap(totalSupply() + amountSharesOut);
    }

    function _mint(address account, uint256 amount) internal virtual override {
        _checkSupplyCap(totalSupply() + amount);
        super._mint(account, amount);
    }
}
