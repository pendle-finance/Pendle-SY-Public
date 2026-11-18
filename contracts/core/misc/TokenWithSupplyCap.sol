// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

abstract contract TokenWithSupplyCap {
    uint256 private _supplyCap;

    uint256[100] private __gap;

    event SupplyCapUpdated(uint256 newSupplyCap);

    error SupplyCapExceeded(uint256 totalSupply, uint256 supplyCap);

    function supplyCap() public view returns (uint256) {
        return _supplyCap;
    }

    function _updateSupplyCap(uint256 newSupplyCap) internal {
        _supplyCap = newSupplyCap;
        emit SupplyCapUpdated(newSupplyCap);
    }

    function _checkSupplyCap(uint256 newSupply) internal view {
        uint256 cap = _supplyCap;
        if (newSupply > cap) revert SupplyCapExceeded(newSupply, cap);
    }
}
