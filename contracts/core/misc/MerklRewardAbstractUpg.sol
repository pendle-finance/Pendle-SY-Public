// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../libraries/TokenHelper.sol";
import "../../interfaces/Angle/IAngleDistributor.sol";

abstract contract MerklRewardAbstract is TokenHelper {
    // solhint-disable immutable-vars-naming
    address public immutable offchainRewardManager;
    address public constant ANGLE_DISTRIBUTOR = 0x3Ef3D8bA38EBe18DB133cEc108f4D14CE00Dd9Ae; // same on every chain

    uint256[49] private __gap; // reserved for future use

    constructor(address _offchainRewardManager) {
        offchainRewardManager = _offchainRewardManager;
    }

    function claimOffchainRewards(
        address tokenReceiver,
        address[] calldata users,
        address[] calldata tokens,
        uint256[] calldata amounts,
        bytes32[][] calldata proofs
    ) external {
        require(msg.sender == offchainRewardManager, "MRA: unauthorized");
        require(users.length == 1 && users[0] == address(this), "MRA: invalid users");

        uint256[] memory preBalance = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; ++i) {
            preBalance[i] = _selfBalance(tokens[i]);
        }

        IAngleDistributor(ANGLE_DISTRIBUTOR).claim(users, tokens, amounts, proofs);

        for (uint256 i = 0; i < tokens.length; ++i) {
            uint256 amountClaimed = _selfBalance(tokens[i]) - preBalance[i];
            if (amountClaimed > 0) {
                _transferOut(tokens[i], tokenReceiver, amountClaimed);
            }
        }
    }
}
