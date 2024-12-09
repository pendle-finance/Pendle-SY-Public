// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IAvalonSaving {
    function totalUnderlying() external view returns (uint256);
    function totalsUSDaLockedAmount() external view returns (uint256);
    function mint(uint256 amount) external;
}
