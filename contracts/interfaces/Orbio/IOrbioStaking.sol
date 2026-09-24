// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IOrbioStaking {
    function stake(uint256 orbioWei) external;

    function unstake(uint256 orbioWei) external returns (uint256 positionWei);

    function settle(uint256[] calldata rewardIds) external returns (uint256 creditAtoms);

    function claim() external returns (uint256 creditMinted);

    function lastRewardId() external view returns (uint256);

    function MAX_PERIODS_PER_CALL() external view returns (uint256);

    function peers()
        external
        view
        returns (
            address orbio,
            address credit,
            address usdg,
            address nvda,
            address feeEscrow,
            address feeFactory,
            address poolManager
        );
}
