// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../PendleERC4626SY.sol";
import "../../../../interfaces/IPTokenWithSupplyCap.sol";

contract PendleSUSDDSY is PendleERC4626SY, IPTokenWithSupplyCap {
    uint256 public supplyCap;

    event SupplyCapUpdated(uint256 newSupplyCap);

    error SupplyCapExceeded(uint256 totalSupply, uint256 supplyCap);

    constructor(address _sUsdd, uint256 _initialSupplyCap) PendleERC4626SY("SY Savings Usdd", "SY-sUSDD", _sUsdd) {
        _updateSupplyCap(_initialSupplyCap);
    }

    /*///////////////////////////////////////////////////////////////
                            SUPPLY CAP UPDATE
    //////////////////////////////////////////////////////////////*/

    function updateSupplyCap(uint256 newSupplyCap) external onlyOwner {
        _updateSupplyCap(newSupplyCap);
    }

    function _updateSupplyCap(uint256 newSupplyCap) internal {
        supplyCap = newSupplyCap;
        emit SupplyCapUpdated(newSupplyCap);
    }

    /*///////////////////////////////////////////////////////////////
                            SUPPLY CAP LOGIC
    //////////////////////////////////////////////////////////////*/

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view override returns (uint256 amountSharesOut) {
        amountSharesOut = super._previewDeposit(tokenIn, amountTokenToDeposit);
        uint256 _newSupply = totalSupply() + amountSharesOut;
        uint256 _supplyCap = supplyCap;

        if (_newSupply > _supplyCap) {
            revert SupplyCapExceeded(_newSupply, _supplyCap);
        }
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

    function getAbsoluteSupplyCap() external view returns (uint256) {
        return supplyCap;
    }

    function getAbsoluteTotalSupply() external view returns (uint256) {
        return totalSupply();
    }
}
