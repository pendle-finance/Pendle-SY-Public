// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../../v2/SYBaseUpgV2.sol";
import "../../../misc/TokenWithSupplyCapUpg.sol";
import "../../../../interfaces/Orbio/IOrbioStaking.sol";

/// @dev The SY must keep at least `staking.MIN_POSITION()` ORBIO staked at all times. Seed it at
/// deploy with shares minted to an irredeemable address before the first user deposit.
contract PendleOrbioStakingSY is SYBaseUpgV2, TokenWithSupplyCapUpg {
    event RewardSettled(uint256 fromId, uint256 toId, uint256 creditAtoms);
    event RewardClaimed(uint256 creditAtoms);
    event RewardSwept(address indexed receiver, uint256 creditAtoms);

    address public immutable staking;
    address public immutable credit;
    address public immutable rewardClaimer;

    uint256 public nextRewardId;

    constructor(address _staking, address _rewardClaimer) SYBaseUpgV2(_orbioOf(_staking)) {
        assert(_rewardClaimer != address(0));
        (, address _credit, , , , , ) = IOrbioStaking(_staking).peers();
        staking = _staking;
        credit = _credit;
        rewardClaimer = _rewardClaimer;
    }

    function _orbioOf(address _staking) private view returns (address orbio) {
        (orbio, , , , , , ) = IOrbioStaking(_staking).peers();
    }

    function initialize(string memory name_, string memory symbol_, address _owner) external initializer {
        __SYBaseUpgV2_init(name_, symbol_, _owner);
        __tokenWithSupplyCap_init(type(uint256).max);
        _safeApproveInf(yieldToken, staking);
        nextRewardId = IOrbioStaking(staking).lastRewardId() + 1;
    }

    /*///////////////////////////////////////////////////////////////
                    DEPOSIT/REDEEM USING BASE TOKENS
    //////////////////////////////////////////////////////////////*/

    function _deposit(address /*tokenIn*/, uint256 amountDeposited) internal override returns (uint256) {
        _settleAndClaim();
        IOrbioStaking(staking).stake(amountDeposited);
        return amountDeposited;
    }

    function _redeem(
        address receiver,
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal override returns (uint256) {
        _settleAndClaim();
        IOrbioStaking(staking).unstake(amountSharesToRedeem);
        _transferOut(yieldToken, receiver, amountSharesToRedeem);
        return amountSharesToRedeem;
    }

    function exchangeRate() external pure override returns (uint256) {
        return PMath.ONE;
    }

    /*///////////////////////////////////////////////////////////////
                               CREDIT
    //////////////////////////////////////////////////////////////*/

    function settleAndClaim() external returns (uint256 creditMinted) {
        return _settleAndClaim();
    }

    function _settleAndClaim() internal returns (uint256 creditMinted) {
        uint256 from = nextRewardId;
        uint256 to = IOrbioStaking(staking).lastRewardId();
        if (to >= from) {
            uint256 maxPeriods = IOrbioStaking(staking).MAX_PERIODS_PER_CALL();
            if (to - from >= maxPeriods) to = from + maxPeriods - 1;
            uint256[] memory ids = new uint256[](to - from + 1);
            for (uint256 i = 0; i < ids.length; ++i) ids[i] = from + i;
            uint256 creditSettled = IOrbioStaking(staking).settle(ids);
            nextRewardId = to + 1;
            emit RewardSettled(from, to, creditSettled);
        }
        creditMinted = IOrbioStaking(staking).claim();
        if (creditMinted != 0) emit RewardClaimed(creditMinted);
    }

    function sweepReward(address receiver) external returns (uint256 creditAtoms) {
        require(msg.sender == rewardClaimer, "PendleOrbioStakingSY: not reward claimer");
        creditAtoms = _selfBalance(credit);
        if (creditAtoms != 0) {
            _transferOut(credit, receiver, creditAtoms);
            emit RewardSwept(receiver, creditAtoms);
        }
    }

    /*///////////////////////////////////////////////////////////////
                MISC METADATA FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _previewDeposit(
        address /*tokenIn*/,
        uint256 amountTokenToDeposit
    ) internal pure override returns (uint256) {
        return amountTokenToDeposit;
    }

    function _previewRedeem(
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal pure override returns (uint256) {
        return amountSharesToRedeem;
    }

    function getTokensIn() public view override returns (address[] memory) {
        return ArrayLib.create(yieldToken);
    }

    function getTokensOut() public view override returns (address[] memory) {
        return ArrayLib.create(yieldToken);
    }

    function isValidTokenIn(address token) public view override returns (bool) {
        return token == yieldToken;
    }

    function isValidTokenOut(address token) public view override returns (bool) {
        return token == yieldToken;
    }

    function assetInfo()
        external
        view
        override
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.TOKEN, yieldToken, IERC20Metadata(yieldToken).decimals());
    }

    /*///////////////////////////////////////////////////////////////
                               SUPPLY-CAP
    //////////////////////////////////////////////////////////////*/

    function getAbsoluteTotalSupply() external view override returns (uint256) {
        return totalSupply();
    }

    function _afterTokenTransfer(address from, address, uint256) internal view override {
        if (from != address(0)) {
            return;
        }
        _checkSupplyCap(totalSupply());
    }
}
