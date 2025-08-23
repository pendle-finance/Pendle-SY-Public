// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IFelixDistributor {
    struct ClaimInfo {
        uint256 distributionId;
        uint256 amount;
    }

    function claimReward(ClaimInfo calldata _claimInfos, bytes32[] calldata _proofs) external;
}
