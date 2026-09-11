// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

interface IPonsFeeShareVault {
    function token() external view returns (address);

    function quoteToken() external view returns (address);
}
