// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../libraries/TokenHelper.sol";
import "../../interfaces/Angle/IAngleDistributor.sol";

abstract contract MerklRewardAbstract__NoStorage is TokenHelper {
    // solhint-disable immutable-vars-naming
    address public immutable offchainRewardManager;
    address public constant ANGLE_DISTRIBUTOR = 0x3Ef3D8bA38EBe18DB133cEc108f4D14CE00Dd9Ae; // same on every chain

    constructor(address _offchainRewardManager) {
        offchainRewardManager = _offchainRewardManager;
    }

    function claimOffchainRewards(
        address[] calldata users,
        address[] calldata tokens,
        uint256[] calldata amounts,
        bytes32[][] calldata proofs,
        address[] calldata recipients,
        bytes[] calldata datas
    ) external {
        require(msg.sender == offchainRewardManager, "MRA: unauthorized");

        uint256 len = users.length;
        require(
            len == tokens.length && len == amounts.length && len == proofs.length && len == recipients.length
                && len == datas.length,
            "MRA: invalid lengths"
        );

        address recipient = recipients[0];

        require(recipient != address(0), "MRA: invalid recipient");

        for (uint256 i = 0; i < len; ++i) {
            require(users[i] == address(this), "MRA: invalid users");
            require(recipients[i] == recipient, "MRA: recipients mismatch");
        }

        IAngleDistributor(ANGLE_DISTRIBUTOR).claimWithRecipient(users, tokens, amounts, proofs, recipients, datas);
    }
}
