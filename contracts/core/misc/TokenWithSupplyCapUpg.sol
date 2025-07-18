// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../../interfaces/IPTokenWithSupplyCap.sol";
import "../libraries/BoringOwnableUpgradeableV2.sol";

abstract contract TokenWithSupplyCapUpg is BoringOwnableUpgradeableV2, IPTokenWithSupplyCap {
    uint256 private _supplyCap;

    uint256[100] private __gap; // reserved for future use

    event SupplyCapUpdated(uint256 newSupplyCap);

    error SupplyCapExceeded(uint256 totalSupply, uint256 supplyCap);

    function __tokenWithSupplyCap_init(uint256 initialSupplyCap) internal onlyInitializing {
        _updateSupplyCap(initialSupplyCap);
    }

    function updateSupplyCap(uint256 newSupplyCap) external onlyOwner {
        _updateSupplyCap(newSupplyCap);
    }

    function getAbsoluteSupplyCap() external view returns (uint256) {
        return _supplyCap;
    }

    function _updateSupplyCap(uint256 newSupplyCap) internal {
        _supplyCap = newSupplyCap;
        emit SupplyCapUpdated(newSupplyCap);
    }

    function _checkSupplyCap(uint256 _supply) internal view {
        uint256 _cap = _supplyCap;
        if (_supply > _cap) {
            revert SupplyCapExceeded(_supply, _cap);
        }
    }
}
