// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.23;

import "./PendleConcreteVaultSY.sol";
import "../../../../interfaces/IPExchangeRateOracle.sol";

contract PendleConcreteLBTCSY is PendleConcreteVaultSY {
    address public immutable oracle;

    constructor(address _concreteVault, address _oracle) PendleConcreteVaultSY(_concreteVault) {
        oracle = _oracle;
    }

    function exchangeRate() public view virtual override returns (uint256) {
        return PMath.mulDown(super.exchangeRate(), IPExchangeRateOracle(oracle).getExchangeRate());
    }
}
