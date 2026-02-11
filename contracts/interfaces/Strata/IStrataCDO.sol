// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IStrataCDO {
    function strategy() external view returns (address);
    function isJrt(address tranche) external view returns (bool);
}
