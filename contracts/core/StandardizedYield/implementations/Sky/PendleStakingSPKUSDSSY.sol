// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../v2/SYBaseWithRewardsUpgV2.sol";
import "../../../../interfaces/Sky/ISkyStaking.sol";
import "../../../../interfaces/Sky/ISkyConverter.sol";

contract PendleStakingSPKUSDSSY is SYBaseWithRewardsUpgV2 {
    address public constant CONVERTER = 0x3225737a9Bbb6473CB4a45b7244ACa2BeFdB276A;
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant USDS = 0xdC035D45d973E3EC169d2276DDab16f1e407384F;
    address public constant SPK = 0xc20059e0317DE91738d13af027DfC4a50781b066;
    address public immutable STAKING_CONTRACT = 0x173e314C7635B45322cd8Cb14f44b312e079F3af;

    constructor() SYBaseWithRewardsUpgV2(USDS) {}

    function initialize(address _owner) external initializer {
        __SYBaseUpgV2_init("SY Staking USDS", "SY-staking-USDS", _owner);
        _safeApproveInf(DAI, CONVERTER);
        _safeApproveInf(USDS, CONVERTER);
        _safeApproveInf(USDS, STAKING_CONTRACT);
    }

    function _deposit(address tokenIn, uint256 amountDeposited) internal virtual override returns (uint256) {
        if (tokenIn == DAI) {
            ISkyConverter(CONVERTER).daiToUsds(address(this), amountDeposited);
        }
        ISkyStaking(STAKING_CONTRACT).stake(amountDeposited);
        return amountDeposited;
    }

    function _redeem(
        address receiver,
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal virtual override returns (uint256) {
        ISkyStaking(STAKING_CONTRACT).withdraw(amountSharesToRedeem);
        if (tokenOut == DAI) {
            ISkyConverter(CONVERTER).usdsToDai(receiver, amountSharesToRedeem);
        } else {
            _transferOut(USDS, receiver, amountSharesToRedeem);
        }
        return amountSharesToRedeem;
    }

    /*///////////////////////////////////////////////////////////////
                               EXCHANGE-RATE
    //////////////////////////////////////////////////////////////*/

    function exchangeRate() public view virtual override returns (uint256) {
        return PMath.ONE;
    }

    /*///////////////////////////////////////////////////////////////
                               REWARDS-RELATED
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See {IStandardizedYield-getRewardTokens}
     */
    function _getRewardTokens() internal pure override returns (address[] memory) {
        return ArrayLib.create(SPK);
    }

    function _redeemExternalReward() internal override {
        ISkyStaking(STAKING_CONTRACT).getReward();
    }

    /*///////////////////////////////////////////////////////////////
                MISC FUNCTIONS FOR METADATA
    //////////////////////////////////////////////////////////////*/

    function _previewDeposit(
        address /*tokenIn*/,
        uint256 amountTokenToDeposit
    ) internal pure override returns (uint256 amountSharesOut) {
        return amountTokenToDeposit;
    }

    function _previewRedeem(
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal pure override returns (uint256 amountTokenOut) {
        return amountSharesToRedeem;
    }

    function getTokensIn() public view virtual override returns (address[] memory) {
        return ArrayLib.create(DAI, USDS);
    }

    function getTokensOut() public view virtual override returns (address[] memory) {
        return ArrayLib.create(DAI, USDS);
    }

    function isValidTokenIn(address token) public view virtual override returns (bool) {
        return token == DAI || token == USDS;
    }

    function isValidTokenOut(address token) public view virtual override returns (bool) {
        return token == DAI || token == USDS;
    }

    function assetInfo() external view returns (AssetType assetType, address assetAddress, uint8 assetDecimals) {
        return (AssetType.TOKEN, USDS, IERC20Metadata(USDS).decimals());
    }
}
