// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../PendleERC20SYUpg.sol";
import "../../../../interfaces/IPExchangeRateOracle.sol";

contract PendleL2BTCLRTSYUpg is PendleERC20SYUpg {
    address public immutable oracle;

    constructor(address _erc20, address _oracle) PendleERC20SYUpg(_erc20) {
        oracle = _oracle;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        require(amount > 0, "transfer zero amount");
    }

    function exchangeRate() public view virtual override returns (uint256) {
        return IPExchangeRateOracle(oracle).getExchangeRate();
    }
}
