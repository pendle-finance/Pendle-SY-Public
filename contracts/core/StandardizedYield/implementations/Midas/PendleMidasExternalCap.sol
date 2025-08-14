// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../../../interfaces/IPTokenWithSupplyCap.sol";
import "../../../../interfaces/Midas/IMidasDepositVault.sol";
import "./libraries/MidasAdapterLib.sol";

interface IPMidasSY {
    function depositVault() external view returns (address);
    function underlying() external view returns (address);
    function yieldToken() external view returns (address);
    function mTokenDataFeed() external view returns (address);
}

contract PendleMidasExternalCap is IPTokenWithSupplyCap {
    address public immutable sy;
    address public immutable depositVault;
    address public immutable underlying;
    address public immutable mToken;
    address public immutable mTokenDataFeed;

    constructor(address _sy) {
        sy = _sy;
        depositVault = IPMidasSY(sy).depositVault();
        underlying = IPMidasSY(sy).underlying();
        mToken = IPMidasSY(sy).yieldToken();
        mTokenDataFeed = IPMidasSY(sy).mTokenDataFeed();
    }

    function getAbsoluteSupplyCap() external view returns (uint256) {
        IMidasDepositVault.TokenConfig memory tokenInConfig = IMidasDepositVault(depositVault).tokensConfig(underlying);

        uint256 amountMTokenCanMint =
            MidasAdapterLib.estimateAmountOutDeposit(depositVault, mTokenDataFeed, underlying, tokenInConfig.allowance);

        return _getAbsoluteTotalSupply() + amountMTokenCanMint;
    }

    function getAbsoluteTotalSupply() external view returns (uint256) {
        return _getAbsoluteTotalSupply();
    }

    function _getAbsoluteTotalSupply() internal view returns (uint256) {
        return IERC20(mToken).totalSupply();
    }
}
