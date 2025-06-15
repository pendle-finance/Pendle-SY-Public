// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../PendleERC4626UpgSYV2.sol";
import "../../SYBaseWithRewardsUpg.sol";
import "../../../../interfaces/Silo/ISiloIncentiveController.sol";

contract PendleSiloV2SY_deprecated is SYBaseWithRewardsUpg {
    address public constant SILO = 0x53f753E4B17F4075D6fa2c6909033d224b81e698;
    address public constant WS = 0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38;
    address public constant xSILO = 0x4451765739b2D7BCe5f8BC95Beaf966c45E1Dcc9;

    address public immutable asset;
    address public immutable incentiveController;

    constructor(address _erc4626, address _incentiveController) SYBaseUpg(_erc4626) {
        asset = IERC4626(_erc4626).asset();
        incentiveController = _incentiveController;
    }

    function initialize(string memory _name, string memory _symbol) external virtual initializer {
        __SYBaseUpg_init(_name, _symbol);
        _safeApproveInf(asset, yieldToken);
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
        return IERC4626(yieldToken).convertToAssets(PMath.ONE);
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
        return (AssetType.TOKEN, asset, IERC20Metadata(asset).decimals());
    }

    /*///////////////////////////////////////////////////////////////
                               REWARDS-RELATED
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See {IStandardizedYield-getRewardTokens}
     */
    function _getRewardTokens() internal pure override returns (address[] memory) {
        return ArrayLib.create(SILO, WS, xSILO);
    }

    function _redeemExternalReward() internal override {
        ISiloIncentiveController(incentiveController).claimRewards(address(this));
    }
}