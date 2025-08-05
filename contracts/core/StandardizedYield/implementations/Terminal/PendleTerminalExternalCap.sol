// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../../../interfaces/IPTokenWithSupplyCap.sol";
import "../../../../interfaces/Terminal/ITerminalFeed.sol";
import "../../../../interfaces/Terminal/ITerminalGenericVault.sol";

interface IPTerminalSYScaled18 {
    function terminalDepositVault() external view returns (address);
    function vaultTokenIn() external view returns (address);
}

contract PendleTerminalExternalCap is IPTokenWithSupplyCap {
    address public immutable sy;
    address public immutable terminalDepositVault;
    address public immutable vaultTokenIn;
    address public immutable mToken;
    address public immutable mTokenDataFeed;

    constructor(address _sy) {
        sy = _sy;
        terminalDepositVault = IPTerminalSYScaled18(_sy).terminalDepositVault();
        vaultTokenIn = IPTerminalSYScaled18(_sy).vaultTokenIn();
        mToken = ITerminalGenericVault(terminalDepositVault).mToken();
        mTokenDataFeed = ITerminalGenericVault(terminalDepositVault).mTokenDataFeed();
    }

    function getAbsoluteSupplyCap() external view returns (uint256) {
        ITerminalGenericVault.TokenConfig memory tokenInConfig = ITerminalGenericVault(terminalDepositVault)
            .tokensConfig(vaultTokenIn);

        uint256 tokenInRate = _getTokenRate(tokenInConfig.dataFeed, tokenInConfig.stable);
        uint256 mTokenRate = _getTokenRate(mTokenDataFeed, false);

        uint256 allowanceInUsd = (tokenInConfig.allowance * tokenInRate) / (10 ** 18);
        uint256 amountMTokenCanMint = (allowanceInUsd * (10 ** 18)) / mTokenRate;
        return _getAbsoluteTotalSupply() + amountMTokenCanMint;
    }

    function getAbsoluteTotalSupply() external view returns (uint256) {
        return _getAbsoluteTotalSupply();
    }

    function _getAbsoluteTotalSupply() internal view returns (uint256) {
        return IERC20(mToken).totalSupply();
    }

    function _getTokenRate(address dataFeed, bool stable) internal view returns (uint256) {
        uint256 rate = ITerminalFeed(dataFeed).getDataInBase18();
        if (stable) return 10 ** 18;
        return rate;
    }
}
