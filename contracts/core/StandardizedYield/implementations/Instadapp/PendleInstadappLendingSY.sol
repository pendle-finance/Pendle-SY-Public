// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../SYBaseWithRewardsUpg.sol";
import "../../../../interfaces/IERC4626.sol";
import "../../../../interfaces/Instadapp/IInstadappStakingRewards.sol";
import "../../../../interfaces/Instadapp/IInstaMerkle.sol";

contract PendleInstadappLendingSY is SYBaseWithRewardsUpg {
    using PMath for uint256;

    event NewStakingRewards(address newStakingRewards);

    address public constant LIQUIDITY = 0x52Aa899454998Be5b000Ad077a46Bbe360F4e497;
    address public constant INST = 0x6f40d4A6237C257fff2dB00FA0510DeEECd303eb;
    address public constant INSTA_MERKLE = 0x7060FE0Dd3E31be01EFAc6B28C8D38018fD163B0;

    // solhint-disable immutable-vars-naming
    address public immutable asset;

    address public stakingRewards;

    constructor(address _fToken) SYBaseUpg(_fToken) {
        assert(block.chainid == 1);
        asset = IERC4626(_fToken).asset();
    }

    function initialize(string memory _name, string memory _symbol) external initializer {
        __SYBaseUpg_init(_name, _symbol);
        _safeApproveInf(asset, yieldToken);
    }

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 /*amountSharesOut*/) {
        uint256 amountToStake;
        if (tokenIn == yieldToken) {
            amountToStake = amountDeposited;
        } else {
            amountToStake = IERC4626(yieldToken).deposit(amountDeposited, address(this));
        }
        if (stakingRewards != address(0)) {
            IInstadappStakingRewards(stakingRewards).stake(amountToStake);
        }
        return amountToStake;
    }

    function _redeem(
        address receiver,
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal override returns (uint256 amountTokenOut) {
        if (stakingRewards != address(0)) {
            IInstadappStakingRewards(stakingRewards).withdraw(amountSharesToRedeem);
        }
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
    ) internal view override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == yieldToken) return amountTokenToDeposit;
        else return IERC4626(yieldToken).previewDeposit(amountTokenToDeposit);
    }

    function _previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal view override returns (uint256 /*amountTokenOut*/) {
        if (tokenOut == yieldToken) return amountSharesToRedeem;
        else return IERC4626(yieldToken).previewRedeem(amountSharesToRedeem);
    }

    function getTokensIn() public view override returns (address[] memory res) {
        res = new address[](2);
        res[0] = asset;
        res[1] = yieldToken;
    }

    function getTokensOut() public view override returns (address[] memory res) {
        res = new address[](2);
        res[0] = asset;
        res[1] = yieldToken;
    }

    function isValidTokenIn(address token) public view override returns (bool) {
        return token == yieldToken || token == asset;
    }

    function isValidTokenOut(address token) public view override returns (bool) {
        return token == yieldToken || token == asset;
    }

    function assetInfo() external view returns (AssetType assetType, address assetAddress, uint8 assetDecimals) {
        return (AssetType.TOKEN, asset, IERC20Metadata(asset).decimals());
    }

    /*///////////////////////////////////////////////////////////////
                               REWARDS-RELATED
    //////////////////////////////////////////////////////////////*/

    function _getRewardTokens() internal pure override returns (address[] memory res) {
        return ArrayLib.create(INST);
    }

    function _redeemExternalReward() internal override {
        if (stakingRewards != address(0)) {
            IInstadappStakingRewards(stakingRewards).getReward();
        }
    }

    function setStakingRewards(address _newStakingRewards) external onlyOwner {
        address _oldStakingRewards = stakingRewards;
        if (_oldStakingRewards != address(0)) {
            IInstadappStakingRewards(_oldStakingRewards).exit();
            _safeApprove(yieldToken, _oldStakingRewards, 0);
        }

        if (_newStakingRewards != address(0)) {
            _safeApproveInf(yieldToken, _newStakingRewards);
            IInstadappStakingRewards(_newStakingRewards).stake(_selfBalance(yieldToken));
        }

        stakingRewards = _newStakingRewards;
        emit NewStakingRewards(_newStakingRewards);
    }

    function claimMerkle(
        address recipient_,
        uint256 cumulativeAmount_,
        uint8 positionType_,
        bytes32 positionId_,
        uint256 cycle_,
        bytes32[] calldata merkleProof_,
        bytes memory metadata_
    ) external onlyOwner {
        IInstaMerkle(INSTA_MERKLE).claim(recipient_, cumulativeAmount_, positionType_, positionId_, cycle_, merkleProof_, metadata_);
    }
}
