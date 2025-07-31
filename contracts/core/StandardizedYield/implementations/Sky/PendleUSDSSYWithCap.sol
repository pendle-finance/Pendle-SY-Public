// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Adapter/extensions/PendleERC20WithAdapterSY.sol";
import "../../../../interfaces/IPTokenWithSupplyCap.sol";

contract PendleUSDSSYWithCap is PendleERC20WithAdapterSY, IPTokenWithSupplyCap {
    uint256 private supplyCap;

    event SupplyCapUpdated(uint256 newSupplyCap);
    error SupplyCapExceeded(uint256 totalSupply, uint256 supplyCap);

    constructor(address _erc20) PendleERC20WithAdapterSY(_erc20) {}


    function getAbsoluteSupplyCap() external view returns (uint256) {
        return supplyCap;
    }

    function getAbsoluteTotalSupply() external view returns (uint256) {
        return totalSupply();
    }


    function updateSupplyCap(uint256 newSupplyCap) external onlyOwner {
        _updateSupplyCap(newSupplyCap);
    }
    
    function _updateSupplyCap(uint256 newSupplyCap) internal {
        supplyCap = newSupplyCap;
        emit SupplyCapUpdated(newSupplyCap);
    }


    // @dev: whenNotPaused not needed as it has already been added to beforeTransfer
    function _afterTokenTransfer(address from, address, uint256) internal virtual override {
        // only check for minting case
        // saving gas on user->user transfers
        // skip supply cap checking on burn to allow lowering supply cap
        if (from != address(0)) {
            return;
        }

        uint256 _supply = totalSupply();
        uint256 _supplyCap = supplyCap;
        if (_supply > _supplyCap) {
            revert SupplyCapExceeded(_supply, _supplyCap);
        }
    }
}