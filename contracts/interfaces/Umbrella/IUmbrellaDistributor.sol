// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

interface IUmbrellaDistributor {
    function claimSelectedRewards(
        address[] calldata assets,
        address[][] calldata rewards,
        address receiver
    ) external returns (uint256[][] memory);
}
