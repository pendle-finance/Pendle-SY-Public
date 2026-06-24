// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../../../interfaces/IERC4626.sol";
import "../../../../interfaces/IPTokenWithSupplyCap.sol";

interface I3JaneProtocolConfig {
    /// @dev Returns the USD3 supply cap, denominated in USDC (6 decimals).
    ///      Returns type(uint256).max when uncapped, 0 when deposits are fully disabled.
    function getUsd3SupplyCap() external view returns (uint256);
}

contract PendleSUSD3ExternalCap is IPTokenWithSupplyCap {
    address public immutable sUSD3;

    constructor(address _sUSD3) {
        sUSD3 = _sUSD3;
    }

    function getAbsoluteSupplyCap() external view returns (uint256) {
        return IERC4626(sUSD3).totalSupply() + IERC4626(sUSD3).maxMint(address(0));
    }

    function getAbsoluteTotalSupply() external view returns (uint256) {
        return IERC4626(sUSD3).totalSupply();
    }
}
