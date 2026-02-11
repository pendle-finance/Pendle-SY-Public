// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PendleHyperbeatVaultSY.sol";

contract PendleHyperbeatLiquidHYPESYV2 is PendleHyperbeatVaultSY {
    address public constant WHYPE = 0x5555555555555555555555555555555555555555;

    constructor(
        address _pricer,
        address _depositor,
        address _withdrawalQueue
    ) PendleHyperbeatVaultSY(_pricer, _depositor, _withdrawalQueue) {}

    function getTokensIn() public view override returns (address[] memory res) {
        return ArrayLib.create(yieldToken, baseAsset, WHYPE);
    }
}
