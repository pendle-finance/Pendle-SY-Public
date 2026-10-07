// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "./PendleERC4626SYYieldTokenScaled18.sol";

contract PendleERC4626NoRedeemSYYieldTokenScaled18 is PendleERC4626SYYieldTokenScaled18 {
    constructor(
        address _erc4626,
        address _decimalsWrapperFactory
    ) PendleERC4626SYYieldTokenScaled18(_erc4626, _decimalsWrapperFactory) {}

    function getTokensOut() public view virtual override returns (address[] memory res) {
        res = new address[](1);
        res[0] = erc4626;
    }

    function isValidTokenOut(address token) public view virtual override returns (bool) {
        return token == erc4626;
    }
}
