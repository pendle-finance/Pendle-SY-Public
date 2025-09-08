// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Midas/PendleMidasSY.sol";
import "../../../../interfaces/IPTokenWithSupplyCap.sol";

contract PendleHyperbeatMidasSY is PendleMidasSY, IPTokenWithSupplyCap {
    using DecimalsCorrectionLibrary for uint256;

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

    function getAbsoluteSupplyCap() external view returns (uint256) {
        address[] memory tokensIn = IMidasManageableVault(depositVault).getPaymentTokens();
        uint256 tokensInLength = tokensIn.length;
        uint256 totalAmountMTokenCanMint = 0;

        for (uint256 i = 0; i < tokensInLength; ++i) {
            IMidasDepositVault.TokenConfig memory tokenInConfig =
                IMidasDepositVault(depositVault).tokensConfig(tokensIn[i]);

            if (tokenInConfig.allowance == type(uint256).max) {
                return type(uint256).max;
            }

            uint256 tokenInDecimals = IERC20Metadata(tokensIn[i]).decimals();

            totalAmountMTokenCanMint += MidasAdapterLib.estimateAmountOutDeposit(
                depositVault, mTokenDataFeed, tokensIn[i], tokenInConfig.allowance.convertFromBase18(tokenInDecimals)
            );
        }

        return _getAbsoluteTotalSupply() + totalAmountMTokenCanMint;
    }

    function getAbsoluteTotalSupply() external view returns (uint256) {
        return _getAbsoluteTotalSupply();
    }

    function _getAbsoluteTotalSupply() internal view returns (uint256) {
        return IERC20(yieldToken).totalSupply();
    }
}
