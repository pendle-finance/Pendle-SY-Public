// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Midas/PendleMidasSY.sol";

contract PendleHyperbeatLiquidHYPESY is PendleMidasSY {
    constructor(
        address _mToken,
        address _depositVault,
        address _redemptionVault,
        address _mTokenDataFeed,
        address _underlying
    ) PendleMidasSY(_mToken, _depositVault, _redemptionVault, _mTokenDataFeed, _underlying) {}

    /// @dev keccak256("hyperbeat.referrers.pendle")
    function PENDLE_REFERRER_ID() public pure override returns (bytes32) {
        return 0x2a176b24a5fec3af048070ad484d82fe4152c8b8eb2edc993ef5700c58ef3d53;
    }

    function getTokensOut() public view override returns (address[] memory res) {
        return ArrayLib.create(yieldToken);
    }

    function isValidTokenOut(address token) public view override returns (bool) {
        return token == yieldToken;
    }
}
