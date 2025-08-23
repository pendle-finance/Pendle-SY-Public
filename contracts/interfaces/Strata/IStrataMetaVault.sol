// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

interface IStrataMetaVault {
    enum PreDepositPhase {
        PointsPhase,
        YieldPhase
    }

    function deposit(address token, uint256 tokenAssets, address receiver) external returns (uint256);

    function redeem(address token, uint256 shares, address receiver, address owner) external returns (uint256);

    function currentPhase() external view returns (PreDepositPhase);
}
