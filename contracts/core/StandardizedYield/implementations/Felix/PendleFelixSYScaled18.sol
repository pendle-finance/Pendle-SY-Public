// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../PendleERC4626SYScaled18.sol";
import "../../../../interfaces/Felix/IFelixDistributor.sol";

contract PendleFelixSYScaled18 is PendleERC4626SYScaled18 {
    // solhint-disable immutable-vars-naming
    address public constant DISTRIBUTOR = 0xbD647dbcCae38A49149C4f3152b26d2a6Ba1EE6E;
    address public immutable offchainRewardManager;

    constructor(
        address _erc4626,
        address _offchainRewardManager,
        address _decimalsWrapperFactory
    ) PendleERC4626SYScaled18(_erc4626, _decimalsWrapperFactory) {
        offchainRewardManager = _offchainRewardManager;
    }

    function claimOffchainRewards(
        address _tokenReceiver,
        address _token,
        IFelixDistributor.ClaimInfo calldata _claimInfos,
        bytes32[] calldata _proofs
    ) external {
        uint256 preBalance = _selfBalance(_token);
        IFelixDistributor(DISTRIBUTOR).claimReward(_claimInfos, _proofs);
        uint256 postBalance = _selfBalance(_token);
        require(postBalance > preBalance, "PFSY: no rewards claimed");
        _transferOut(_token, _tokenReceiver, postBalance - preBalance);
    }
}
