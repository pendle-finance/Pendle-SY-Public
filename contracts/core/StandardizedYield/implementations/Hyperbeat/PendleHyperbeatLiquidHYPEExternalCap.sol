// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PendleMidasExternalCap} from "../Midas/PendleMidasExternalCap.sol";

contract PendleHyperbeatLiquidHYPEExternalCap is PendleMidasExternalCap {
    constructor(address _sy) PendleMidasExternalCap(_sy) {}
}
