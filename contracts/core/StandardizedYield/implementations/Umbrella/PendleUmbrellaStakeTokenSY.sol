// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../../v2/SYBaseWithRewardsUpgV2.sol";
import "../../../../interfaces/IERC4626.sol";
import "./UmbrellaLib.sol";
import "../../../../interfaces/Umbrella/IUmbrellaDistributor.sol";

contract PendleUmbrellaStakeTokenSY is SYBaseWithRewardsUpgV2 {
    using PMath for uint256;

    address public immutable asset;
    address public immutable distributor;

    constructor(address _erc4626, address _distributor) SYBaseWithRewardsUpgV2(_erc4626) {
        distributor = _distributor;
        asset = IERC4626(_erc4626).asset();
    }

    function initialize(string memory _name, string memory _symbol, address _owner) external virtual initializer {
        __SYBaseUpgV2_init(_name, _symbol, _owner);
        _safeApproveInf(asset, yieldToken);
    }

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 amountSharesOut) {
        if (tokenIn == yieldToken) {
            return amountDeposited;
        } else {
            return IERC4626(yieldToken).deposit(amountDeposited, address(this));
        }
    }

    function _redeem(
        address receiver,
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal virtual override returns (uint256) {
        _transferOut(yieldToken, receiver, amountSharesToRedeem);
        return amountSharesToRedeem;
    }

    function exchangeRate() public view virtual override returns (uint256) {
        return IERC4626(yieldToken).convertToShares(PMath.ONE);
    }

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view virtual override returns (uint256 amountSharesOut) {
        if (tokenIn == yieldToken) {
            return amountTokenToDeposit;
        } else {
            return IERC4626(yieldToken).previewDeposit(amountTokenToDeposit);
        }
    }

    function _previewRedeem(
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal view virtual override returns (uint256 /*amountTokenOut*/) {
        return amountSharesToRedeem;
    }

    function getTokensIn() public view virtual override returns (address[] memory res) {
        return ArrayLib.create(asset, yieldToken);
    }

    function getTokensOut() public view virtual override returns (address[] memory res) {
        return ArrayLib.create(yieldToken);
    }

    function isValidTokenIn(address token) public view virtual override returns (bool) {
        return token == yieldToken || token == asset;
    }

    function isValidTokenOut(address token) public view virtual override returns (bool) {
        return token == yieldToken;
    }

    function assetInfo()
        external
        view
        virtual
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.TOKEN, asset, IERC20Metadata(asset).decimals());
    }

    function _getPath() internal view returns (address[] memory) {
        return ArrayLib.create(asset, yieldToken);
    }

    /*///////////////////////////////////////////////////////////////
                               REWARDS-RELATED
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See {IStandardizedYield-getRewardTokens}
     */
    function _getRewardTokens() internal view override returns (address[] memory) {
        return ArrayLib.create(asset);
    }

    function _redeemExternalReward() internal override {
        address[][] memory rwdTokens = new address[][](1);
        rwdTokens[0] = ArrayLib.create(asset);
        IUmbrellaDistributor(distributor).claimSelectedRewards(ArrayLib.create(yieldToken), rwdTokens, address(this));
    }
}
