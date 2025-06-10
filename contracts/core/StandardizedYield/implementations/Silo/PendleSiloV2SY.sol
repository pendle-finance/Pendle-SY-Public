// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../PendleERC4626UpgSYV2.sol";
import "../../SYBaseWithRewardsUpg.sol";
import "../../../../interfaces/Silo/ISiloIncentiveController.sol";
import "../../../../interfaces/IPDecimalsWrapperFactory.sol";
import "../../../../interfaces/IStandardizedYieldExtended.sol";

contract PendleSiloV2SY is SYBaseWithRewardsUpg, IStandardizedYieldExtended {
    address public immutable asset;
    address public immutable wrappedAsset;
    address public immutable incentiveController;
    uint256 public immutable assetScalingOffset;

    address[] public rewardTokens;

    constructor(address _erc4626, address _incentiveController, address _decimalsWrapperFactory) SYBaseUpg(_erc4626) {
        asset = IERC4626(_erc4626).asset();
        incentiveController = _incentiveController;

        if (IERC20Metadata(asset).decimals() < 18) {
            wrappedAsset = IPDecimalsWrapperFactory(_decimalsWrapperFactory).getOrCreate(asset, 18);
            assetScalingOffset = 10 ** (18 - IERC20Metadata(asset).decimals());
        } else {
            wrappedAsset = asset;
            assetScalingOffset = 1;
        }
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        address[] memory _rewardTokens
    ) external virtual initializer {
        __SYBaseUpg_init(_name, _symbol);
        _safeApproveInf(asset, yieldToken);
        rewardTokens = _rewardTokens;
    }

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == yieldToken) {
            return amountDeposited;
        } else {
            return IERC4626(yieldToken).deposit(amountDeposited, address(this));
        }
    }

    function _redeem(
        address receiver,
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal virtual override returns (uint256 amountTokenOut) {
        if (tokenOut == yieldToken) {
            amountTokenOut = amountSharesToRedeem;
            _transferOut(yieldToken, receiver, amountTokenOut);
        } else {
            amountTokenOut = IERC4626(yieldToken).redeem(amountSharesToRedeem, receiver, address(this));
        }
    }

    function exchangeRate() public view virtual override returns (uint256) {
        return IERC4626(yieldToken).convertToAssets(PMath.ONE * assetScalingOffset);
    }

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == yieldToken) return amountTokenToDeposit;
        else return IERC4626(yieldToken).previewDeposit(amountTokenToDeposit);
    }

    function _previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal view virtual override returns (uint256 /*amountTokenOut*/) {
        if (tokenOut == yieldToken) return amountSharesToRedeem;
        else return IERC4626(yieldToken).previewRedeem(amountSharesToRedeem);
    }

    function getTokensIn() public view virtual override returns (address[] memory res) {
        res = new address[](2);
        res[0] = asset;
        res[1] = yieldToken;
    }

    function getTokensOut() public view virtual override returns (address[] memory res) {
        res = new address[](2);
        res[0] = asset;
        res[1] = yieldToken;
    }

    function isValidTokenIn(address token) public view virtual override returns (bool) {
        return token == yieldToken || token == asset;
    }

    function isValidTokenOut(address token) public view virtual override returns (bool) {
        return token == yieldToken || token == asset;
    }

    function assetInfo()
        external
        view
        virtual
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.TOKEN, wrappedAsset, 18);
    }

    function pricingInfo() external view returns (address refToken, bool refStrictlyEqual) {
        return (yieldToken, true);
    }

    /*///////////////////////////////////////////////////////////////
                               REWARDS-RELATED
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See {IStandardizedYield-getRewardTokens}
     */
    function _getRewardTokens() internal view override returns (address[] memory) {
        return rewardTokens;
    }

    function _redeemExternalReward() internal override {
        ISiloIncentiveController(incentiveController).claimRewards(address(this));
    }
}
