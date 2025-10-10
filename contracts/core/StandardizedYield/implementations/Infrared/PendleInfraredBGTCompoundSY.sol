// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../SYBaseWithRewardsUpg.sol";
import "../../../../interfaces/Infrared/IInfraredBGTVault.sol";

contract PendleInfraredBGTCompoundSY is SYBaseWithRewardsUpg {
    using PMath for uint256;

    address public constant VAULT = 0x75F3Be06b02E235f6d0E7EF2D462b29739168301;
    address public constant IBGT = 0xac03CABA51e17c86c921E1f6CBFBdC91F8BB2E6b;
    address public constant HONEY = 0xFCBD14DC51f0A4d49d5E53C2E0950e0bC26d0Dce;
    address public constant BERA = 0x6969696969696969696969696969696969696969;
    address public constant WIBGT = 0x4f3C10D2bC480638048Fa67a7D00237a33670C1B;

    uint256 private constant MINIMUM_LIQUIDITY = 1e9;

    uint8 private constant _NOT_CLAIMING = 1;
    uint8 private constant _CLAIMING = 2;
    uint8 private _rewardClaimState;

    modifier notInRewardClaimingProcess() {
        require(_rewardClaimState != _CLAIMING, "SY: in reward claim");
        _;
    }

    constructor() SYBaseUpg(IBGT) {}

    function initialize() external initializer {
        __SYBaseUpg_init("SY Staked Infrared BGT", "SY-iBGT");
        _safeApproveInf(IBGT, VAULT);
        _rewardClaimState = _NOT_CLAIMING;
    }

    function _deposit(address /*tokenIn*/, uint256 amountDeposited)
        internal
        virtual
        override
        returns (uint256 amountSharesOut)
    {
        _harvestAndCompound();

        if (totalSupply() == 0) {
            amountSharesOut = amountDeposited - MINIMUM_LIQUIDITY;
            _mint(address(1), MINIMUM_LIQUIDITY);
        } else {
            uint256 priorTotalAssetOwned = getTotalAssetOwned() - amountDeposited;
            amountSharesOut = (amountDeposited * totalSupply()) / priorTotalAssetOwned;
        }
    }

    function _redeem(address receiver, address /*tokenOut*/, uint256 amountSharesToRedeem)
        internal
        override
        returns (uint256 amountTokenOut)
    {
        // note: _harvestAndCompound() already called when burning shares.

        uint256 priorTotalSupply = totalSupply() + amountSharesToRedeem;
        amountTokenOut = amountSharesToRedeem * getTotalAssetOwned() / priorTotalSupply;

        IInfraredBGTVault(VAULT).withdraw(amountTokenOut);
        _transferOut(IBGT, receiver, amountTokenOut);
    }

    function exchangeRate() public view virtual override notInRewardClaimingProcess returns (uint256 res) {
        uint256 _totalSupply = totalSupply();
        if (_totalSupply == 0) {
            res = PMath.ONE;
        } else {
            res = getTotalAssetOwned().divDown(_totalSupply);
        }
    }

    function _previewDeposit(address /*tokenIn*/, uint256 amountTokenToDeposit)
        internal
        view
        override
        returns (uint256 amountSharesOut)
    {
        uint256 _totalSupply = totalSupply();
        if (_totalSupply == 0) {
            amountSharesOut = amountTokenToDeposit - MINIMUM_LIQUIDITY;
        } else {
            amountSharesOut = amountTokenToDeposit * _totalSupply / getTotalAssetOwned();
        }
    }

    function _previewRedeem(address /*tokenOut*/, uint256 amountSharesToRedeem)
        internal
        view
        override
        returns (uint256 /*amountTokenOut*/ )
    {
        // This function is intentionally left reverted when totalSupply() = 0
        return amountSharesToRedeem * getTotalAssetOwned() / totalSupply();
    }

    function getTokensIn() public pure override returns (address[] memory res) {
        return ArrayLib.create(IBGT);
    }

    function getTokensOut() public pure override returns (address[] memory res) {
        return ArrayLib.create(IBGT);
    }

    function isValidTokenIn(address token) public pure override returns (bool) {
        return token == IBGT;
    }

    function isValidTokenOut(address token) public pure override returns (bool) {
        return token == IBGT;
    }

    function assetInfo() external pure returns (AssetType assetType, address assetAddress, uint8 assetDecimals) {
        return (AssetType.TOKEN, IBGT, 18);
    }

    /*///////////////////////////////////////////////////////////////
                AUTOCOMPOUND FEATURE
    //////////////////////////////////////////////////////////////*/

    function getTotalAssetOwned() public view returns (uint256 totalAssetOwned) {
        uint256 stakedAmount = IInfraredBGTVault(VAULT).balanceOf(address(this));
        // uint256 pendingRewardAmount = IInfraredBGTVault(VAULT).earned(address(this), IBGT);
        uint256 floatingAmount = _selfBalance(IBGT);

        totalAssetOwned = stakedAmount + floatingAmount;
    }

    function harvestAndCompound() external nonReentrant {
        _harvestAndCompound();
    }

    function _harvestAndCompound() internal {
        _harvest();
        _compound();
    }

    function _harvest() internal {
        _rewardClaimState = _CLAIMING;
        IInfraredBGTVault(VAULT).getRewardForUser(address(this));
        _rewardClaimState = _NOT_CLAIMING;
    }

    function _compound() internal {
        uint256 amountToCompound = _selfBalance(IBGT);
        if (amountToCompound == 0) return;
        IInfraredBGTVault(VAULT).stake(amountToCompound);
    }

    /*///////////////////////////////////////////////////////////////
                               REWARDS-RELATED
    //////////////////////////////////////////////////////////////*/

    function _getRewardTokens() internal pure override returns (address[] memory res) {
        return ArrayLib.create(HONEY, BERA, WIBGT);
    }

    function _redeemExternalReward() internal override {
        _harvestAndCompound();
    }
}
