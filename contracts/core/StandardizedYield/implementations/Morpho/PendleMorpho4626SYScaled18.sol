// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../PendleERC4626SYScaled18.sol";
import "../../../misc/MerklRewardAbstractUpg.sol";

contract PendleMorpho4626SYScaled18 is PendleERC4626SYScaled18, MerklRewardAbstract {
    constructor(
        address _erc4626,
        address _decimalsWrapperFactory,
        address _offchainReceiver
    ) PendleERC4626SYScaled18(_erc4626, _decimalsWrapperFactory) MerklRewardAbstract(_offchainReceiver) {}
}
