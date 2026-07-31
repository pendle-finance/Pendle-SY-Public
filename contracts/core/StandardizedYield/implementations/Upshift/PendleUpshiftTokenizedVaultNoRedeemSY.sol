// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PendleUpshiftTokenizedVaultSY.sol";

contract PendleUpshiftTokenizedVaultNoRedeemSY is PendleUpshiftTokenizedVaultSY {
    constructor(
        address _yieldToken,
        address _tokenizedVault
    ) PendleUpshiftTokenizedVaultSY(_yieldToken, _tokenizedVault) {}

    function getTokensOut() public view override returns (address[] memory res) {
        return ArrayLib.create(yieldToken);
    }

    function isValidTokenOut(address token) public view override returns (bool) {
        return token == yieldToken;
    }
}
