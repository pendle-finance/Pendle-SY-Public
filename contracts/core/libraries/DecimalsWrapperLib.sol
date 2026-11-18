// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../../interfaces/IPDecimalsWrapperFactory.sol";

/// @dev Tokens above 18 decimals are rejected, so a token from `scaled18` always has 18 decimals.
library DecimalsWrapperLib {
    function scaled18(address factory, address token) internal returns (address) {
        return _decimals(token) < 18 ? IPDecimalsWrapperFactory(factory).getOrCreate(token, 18) : token;
    }

    function scale18(address token) internal view returns (uint256) {
        return 10 ** (18 - _decimals(token));
    }

    function _decimals(address token) private view returns (uint8 decimals) {
        decimals = IERC20Metadata(token).decimals();
        require(decimals <= 18, "DecimalsWrapperLib: decimals > 18");
    }
}
