// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {PendleUSDESY} from "./PendleUSDESY.sol";
import {MerklRewardAbstract__NoStorage} from "../../../misc/MerklRewardAbstract__NoStorage.sol";

contract PendleUSDEOffchainRewardsSY is PendleUSDESY, MerklRewardAbstract__NoStorage {
    constructor(address _usde, uint256 _initialSupplyCap, address _offchainRewardManager)
        PendleUSDESY(_usde, _initialSupplyCap)
        MerklRewardAbstract__NoStorage(_offchainRewardManager)
    {}
}
