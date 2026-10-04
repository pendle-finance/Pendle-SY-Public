// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @dev Representative accounting unit for PendleTokenizedStocksSY. One unit denotes one underlying share for
///      pricing and metadata purposes only. It is not a wrapper, is never minted, cannot be transferred, and confers
///      no ownership, claim, or right on any security or on the tokenized stock the SY holds.
contract PendleTokenizedStocksShareToken is IERC20Metadata {
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function totalSupply() external pure returns (uint256) {
        return 0;
    }

    function balanceOf(address) external pure returns (uint256) {
        return 0;
    }

    function allowance(address, address) external pure returns (uint256) {
        return 0;
    }

    function transfer(address, uint256) external pure returns (bool) {
        revert("PTSST: non-transferable");
    }

    function approve(address, uint256) external pure returns (bool) {
        revert("PTSST: non-transferable");
    }

    function transferFrom(address, address, uint256) external pure returns (bool) {
        revert("PTSST: non-transferable");
    }
}
