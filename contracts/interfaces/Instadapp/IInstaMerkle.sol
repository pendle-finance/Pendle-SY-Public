// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

interface IInstaMerkle {
    function claim(
        address recipient_,
        uint256 cumulativeAmount_,
        uint8 positionType_,
        bytes32 positionId_,
        uint256 cycle_,
        bytes32[] calldata merkleProof_,
        bytes memory metadata_
    ) external;
}
