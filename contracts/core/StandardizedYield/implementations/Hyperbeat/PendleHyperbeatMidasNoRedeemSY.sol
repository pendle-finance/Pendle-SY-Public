// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PendleHyperbeatMidasSY.sol";

contract PendleHyperbeatMidasNoRedeemSY is PendleHyperbeatMidasSY {
    constructor(
        address _mToken,
        address _depositVault,
        address _redemptionVault,
        address _mTokenDataFeed,
        address _underlying
    ) PendleHyperbeatMidasSY(_mToken, _depositVault, _redemptionVault, _mTokenDataFeed, _underlying) {}

    function getTokensOut() public view override returns (address[] memory res) {
        return ArrayLib.create(yieldToken);
    }

    function isValidTokenOut(address token) public view override returns (bool) {
        return token == yieldToken;
    }
}
