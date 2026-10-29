// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {TokenHelper} from "../../../libraries/TokenHelper.sol";
import {ArrayLib} from "../../../libraries/ArrayLib.sol";
import {IStandardizedYieldAdapter} from "../../../../interfaces/IStandardizedYieldAdapter.sol";
import {IMachine} from "../../../../interfaces/Makina/IMachine.sol";
import {IDirectDepositor} from "../../../../interfaces/Makina/IDirectDepositor.sol";

contract PendleMakinaDepositAdapter is IStandardizedYieldAdapter, TokenHelper {
    bytes32 public constant REFERRAL_KEY = "pendle.finance";

    address public immutable depositor;
    address public immutable machine;
    address public immutable accountingToken;
    address public immutable shareToken;

    constructor(address _depositor) {
        depositor = _depositor;
        machine = IDirectDepositor(_depositor).machine();
        accountingToken = IMachine(machine).accountingToken();
        shareToken = IMachine(machine).shareToken();

        _safeApproveInf(accountingToken, _depositor);
    }

    function PIVOT_TOKEN() external view returns (address pivotToken) {
        return shareToken;
    }

    /*///////////////////////////////////////////////////////////////
                                DEPOSIT
    //////////////////////////////////////////////////////////////*/

    function convertToDeposit(address /*tokenIn*/, uint256 amountTokenIn) external returns (uint256 amountOut) {
        return IDirectDepositor(depositor).deposit(amountTokenIn, msg.sender, 0, REFERRAL_KEY);
    }

    function previewConvertToDeposit(
        address /*tokenIn*/,
        uint256 amountTokenIn
    ) external view returns (uint256 amountOut) {
        amountOut = IMachine(machine).convertToShares(amountTokenIn);
        require(amountOut <= IMachine(machine).maxMint(), "exceeds capacity");
    }

    function getAdapterTokensDeposit() external view returns (address[] memory tokens) {
        return ArrayLib.create(accountingToken);
    }

    /*///////////////////////////////////////////////////////////////
                                REDEEM
    //////////////////////////////////////////////////////////////*/

    function convertToRedeem(
        address /*tokenOut*/,
        uint256 /*amountPivotTokenIn*/
    ) external pure returns (uint256 /*amountOut*/) {
        revert("not supported");
    }

    function previewConvertToRedeem(
        address /*tokenOut*/,
        uint256 /*amountPivotTokenIn*/
    ) external pure returns (uint256 /*amountOut*/) {
        revert("not supported");
    }

    function getAdapterTokensRedeem() external pure returns (address[] memory tokens) {
        return new address[](0);
    }
}
