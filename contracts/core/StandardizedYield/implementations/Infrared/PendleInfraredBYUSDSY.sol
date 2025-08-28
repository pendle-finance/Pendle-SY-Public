// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {SYBaseWithRewardsUpgV2} from "../../v2/SYBaseWithRewardsUpgV2.sol";
import {PMath} from "contracts/core/libraries/math/PMath.sol";
import {ArrayLib} from "contracts/core/libraries/ArrayLib.sol";
import {IInfraredBYUSDVault} from "../../../../interfaces/Infrared/IInfraredBYUSDVault.sol";
import {IWrappedRewardToken} from "../../../../interfaces/Infrared/IWrappedRewardToken.sol";

contract PendleInfraredBYUSDSY is SYBaseWithRewardsUpgV2 {
    address public constant VAULT = 0xbbB228B0D7D83F86e23a5eF3B1007D0100581613;
    address public constant IBGT = 0xac03CABA51e17c86c921E1f6CBFBdC91F8BB2E6b;
    address public constant BYUSD = 0x688e72142674041f8f6Af4c808a4045cA1D6aC82;
    IWrappedRewardToken public constant WBYUSD = IWrappedRewardToken(0x334404782aB67b4F6B2A619873E579E971f9AAB7);
    address public constant BYUSD_HONEY_LP = 0xdE04c469Ad658163e2a5E860a03A86B52f6FA8C8;

    constructor() SYBaseWithRewardsUpgV2(BYUSD_HONEY_LP) {}

    function initialize(address _owner) external initializer {
        __SYBaseUpgV2_init("SY Staked Infrared BYUSD-HONEY", "SY-iBYUSD-HONEY", _owner);
        _safeApproveInf(BYUSD_HONEY_LP, VAULT);
    }

    function _deposit(
        address /*tokenIn*/,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 /*amountSharesOut*/) {
        IInfraredBYUSDVault(VAULT).stake(amountDeposited);
        return amountDeposited;
    }

    function _redeem(
        address receiver,
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal override returns (uint256) {
        IInfraredBYUSDVault(VAULT).withdraw(amountSharesToRedeem);
        _transferOut(BYUSD_HONEY_LP, receiver, amountSharesToRedeem);
        return amountSharesToRedeem;
    }

    function exchangeRate() public view virtual override returns (uint256) {
        return PMath.ONE;
    }

    function _previewDeposit(
        address /*tokenIn*/,
        uint256 amountTokenToDeposit
    ) internal pure override returns (uint256 /*amountSharesOut*/) {
        return amountTokenToDeposit;
    }

    function _previewRedeem(
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal pure override returns (uint256 /*amountTokenOut*/) {
        return amountSharesToRedeem;
    }

    function getTokensIn() public pure override returns (address[] memory res) {
        return ArrayLib.create(BYUSD_HONEY_LP);
    }

    function getTokensOut() public pure override returns (address[] memory res) {
        return ArrayLib.create(BYUSD_HONEY_LP);
    }

    function isValidTokenIn(address token) public pure override returns (bool) {
        return token == BYUSD_HONEY_LP;
    }

    function isValidTokenOut(address token) public pure override returns (bool) {
        return token == BYUSD_HONEY_LP;
    }

    function assetInfo() external pure returns (AssetType assetType, address assetAddress, uint8 assetDecimals) {
        return (AssetType.TOKEN, BYUSD_HONEY_LP, 18);
    }

    /*///////////////////////////////////////////////////////////////
                               REWARDS-RELATED
    //////////////////////////////////////////////////////////////*/

    function _getRewardTokens() internal pure override returns (address[] memory res) {
        return ArrayLib.create(IBGT, BYUSD);
    }

    function _redeemExternalReward() internal override {
        // get rewards and unwrap WBYUSD
        IInfraredBYUSDVault(VAULT).getRewardForUser(address(this));
        uint256 amountWBYUSD = WBYUSD.balanceOf(address(this));        
        // dust check
        if (WBYUSD.previewRedeem(amountWBYUSD) > 0) {
            // redeem WBYUSD (18 decimals) for BYUSD (6 decimals)
            WBYUSD.redeem(amountWBYUSD, address(this), address(this));
        }        
    }
}
