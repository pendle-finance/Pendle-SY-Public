// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IPRateLimiter {
    function onMint(address caller, uint256 amount) external;

    function onBurn(address caller, uint256 amount) external;
}
