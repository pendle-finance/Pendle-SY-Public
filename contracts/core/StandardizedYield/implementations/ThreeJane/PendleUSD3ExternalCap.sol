// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../../../interfaces/IERC4626.sol";
import "../../../../interfaces/IPTokenWithSupplyCap.sol";

interface IUSD3 is IERC4626 {
    function morphoCredit() external view returns (address);
}

interface IMorphoCredit3Jane {
    function protocolConfig() external view returns (address);
}

interface I3JaneProtocolConfig {
    /// @dev Returns the USD3 supply cap, denominated in USDC (6 decimals).
    ///      Returns type(uint256).max when uncapped, 0 when deposits are fully disabled.
    function getUsd3SupplyCap() external view returns (uint256);
}

contract PendleUSD3ExternalCap is IPTokenWithSupplyCap {
    address public immutable USD3;

    constructor(address _USD3) {
        USD3 = _USD3;
    }

    function getAbsoluteSupplyCap() external view returns (uint256) {
        address morphoCredit = IUSD3(USD3).morphoCredit();
        address protocolConfig = IMorphoCredit3Jane(morphoCredit).protocolConfig();
        uint256 usdcCap = I3JaneProtocolConfig(protocolConfig).getUsd3SupplyCap();
        if (usdcCap == 0) return 0;
        if (usdcCap == type(uint256).max) return type(uint256).max;

        return IERC4626(USD3).convertToShares(usdcCap);
    }

    function getAbsoluteTotalSupply() external view returns (uint256) {
        return IERC4626(USD3).totalSupply();
    }
}
