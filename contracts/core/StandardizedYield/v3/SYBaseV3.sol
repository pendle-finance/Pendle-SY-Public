// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../v2/SYBaseV2.sol";
import "../../misc/TokenWithSupplyCap.sol";

abstract contract SYBaseV3 is SYBaseV2, TokenWithSupplyCap {
    constructor(string memory _name, string memory _symbol, address _yieldToken) SYBaseV2(_name, _symbol, _yieldToken) {
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
