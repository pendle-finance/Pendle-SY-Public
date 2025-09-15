// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
    using DecimalsCorrectionLibrary for uint256;

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
        address[] memory tokensIn = IMidasManageableVault(depositVault).getPaymentTokens();
        uint256 tokensInLength = tokensIn.length;
        uint256 totalAmountMTokenCanMint = 0;

        for (uint256 i = 0; i < tokensInLength; ++i) {
            IMidasDepositVault.TokenConfig memory tokenInConfig = IMidasDepositVault(depositVault).tokensConfig(
                tokensIn[i]
            );

            if (tokenInConfig.allowance == type(uint256).max) {
                return type(uint256).max;
            }

            uint256 tokenInDecimals = IERC20Metadata(tokensIn[i]).decimals();

            totalAmountMTokenCanMint += MidasAdapterLib.estimateAmountOutDeposit(
                depositVault,
                mTokenDataFeed,
                tokensIn[i],
                tokenInConfig.allowance.convertFromBase18(tokenInDecimals)
            );
        }

        return _getAbsoluteTotalSupply() + totalAmountMTokenCanMint;
    }

    function getAbsoluteTotalSupply() external view returns (uint256) {
        return _getAbsoluteTotalSupply();
    }

    function _getAbsoluteTotalSupply() internal view returns (uint256) {
        return IERC20(mToken).totalSupply();
    }
}
