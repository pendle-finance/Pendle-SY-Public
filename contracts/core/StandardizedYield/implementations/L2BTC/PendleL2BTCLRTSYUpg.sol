// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../PendleERC20SYUpg.sol";

contract PendleL2BTCLRTSYUpg is PendleERC20SYUpg {
    constructor(address _erc20) PendleERC20SYUpg(_erc20) {}

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override virtual {
        super._beforeTokenTransfer(from, to, amount);
        require (amount > 0, "transfer zero amount");
    }
}