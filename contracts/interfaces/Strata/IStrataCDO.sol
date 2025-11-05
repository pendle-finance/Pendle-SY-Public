// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./IStrataStrategy.sol";

interface IStrataCDO {
    function strategy() external view returns (IStrataStrategy);
}
