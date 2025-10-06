// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.23;

import "./PendleAaveV3WithRewardsSYUpg.sol";
import "../../../misc/MerklRewardAbstract__NoStorage.sol";

contract PendleAaveV3MerklRewardsSYUpg is PendleAaveV3WithRewardsSYUpg, MerklRewardAbstract__NoStorage {
    constructor(
        address _aavePool,
        address _aToken,
        address _initialIncentiveController,
        address _defaultRewardToken,
        address _offchainRewardManager
    )
        PendleAaveV3WithRewardsSYUpg(_aavePool, _aToken, _initialIncentiveController, _defaultRewardToken)
        MerklRewardAbstract__NoStorage(_offchainRewardManager)
    {}

    function _getRewardTokens() internal pure override returns (address[] memory) {
        return new address[](0);
    }
}
