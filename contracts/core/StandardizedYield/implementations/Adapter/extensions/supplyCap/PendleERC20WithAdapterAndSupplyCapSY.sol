// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../PendleERC20WithAdapterSY.sol";
import "../../../../../../interfaces/IPTokenWithSupplyCap.sol";

contract PendleERC20WithAdapterAndSupplyCapSY is PendleERC20WithAdapterSY, IPTokenWithSupplyCap {
    uint256 public supplyCap;
    uint256[100] private __gap;

    event SupplyCapUpdated(uint256 newSupplyCap);

    error SupplyCapExceeded(uint256 totalSupply, uint256 supplyCap);

    constructor(
        address _erc20,
        address _offchainRewardManager
    ) PendleERC20WithAdapterSY(_erc20, _offchainRewardManager) {}

    function initialize(
        string memory _name,
        string memory _symbol,
        address _adapter
    ) external virtual override initializer {
        __SYBaseUpg_init(_name, _symbol);
        _setAdapter(_adapter);
        _updateSupplyCap(type(uint256).max);
    }

    function updateSupplyCap(uint256 newSupplyCap) external onlyOwner {
        _updateSupplyCap(newSupplyCap);
    }

    function _updateSupplyCap(uint256 newSupplyCap) internal {
        supplyCap = newSupplyCap;
        emit SupplyCapUpdated(newSupplyCap);
    }

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view virtual override returns (uint256 amountSharesOut) {
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
