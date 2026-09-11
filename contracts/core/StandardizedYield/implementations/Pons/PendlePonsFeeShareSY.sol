// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.23;

import "../../v2/SYBaseWithRewardsUpgV2.sol";
import "../../../../interfaces/Pons/IPonsFeeShareVault.sol";

/// @notice Rewards vest before they are indexed, so a JIT deposit captures almost nothing.
/// @dev Do not use where the reward token has fewer decimals than the yield token.
contract PendlePonsFeeShareSY is SYBaseWithRewardsUpgV2 {
    using PMath for uint256;

    error ZeroVestingDuration();

    event VestingDurationUpdated(uint256 newDuration);

    address public immutable feeShareVault;
    address public immutable rewardToken;

    uint256 public vestingDuration;
    uint256 public lastVestAt;

    constructor(address _yieldToken, address _feeShareVault) SYBaseWithRewardsUpgV2(_yieldToken) {
        address quoteToken = IPonsFeeShareVault(_feeShareVault).quoteToken();
        assert(quoteToken != address(0) && quoteToken != yieldToken);
        assert(IPonsFeeShareVault(_feeShareVault).token() == yieldToken);

        feeShareVault = _feeShareVault;
        rewardToken = quoteToken;
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        address _owner,
        uint256 _vestingDuration
    ) external virtual initializer {
        __SYBaseUpgV2_init(_name, _symbol, _owner);
        _setVestingDuration(_vestingDuration);
        lastVestAt = block.timestamp;
    }

    /*///////////////////////////////////////////////////////////////
                    DEPOSIT/REDEEM USING BASE TOKENS
    //////////////////////////////////////////////////////////////*/

    function _deposit(address /*tokenIn*/, uint256 amountDeposited) internal virtual override returns (uint256) {
        return amountDeposited;
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
        return PMath.ONE;
    }

    function _previewDeposit(
        address /*tokenIn*/,
        uint256 amountTokenToDeposit
    ) internal view virtual override returns (uint256) {
        return amountTokenToDeposit;
    }

    function _previewRedeem(
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal view virtual override returns (uint256) {
        return amountSharesToRedeem;
    }

    /*///////////////////////////////////////////////////////////////
                               REWARDS
    //////////////////////////////////////////////////////////////*/

    function _updateRewardIndex()
        internal
        virtual
        override
        returns (address[] memory tokens, uint256[] memory indexes)
    {
        address token = rewardToken;

        tokens = ArrayLib.create(token);
        indexes = new uint256[](1);

        if (lastRewardBlock == block.number) {
            indexes[0] = rewardState[token].index;
            return (tokens, indexes);
        }
        lastRewardBlock = block.number;

        RewardState memory state = rewardState[token];
        (uint256 lastBalance, uint256 index) = (state.lastBalance, state.index);
        if (index == 0) index = INITIAL_REWARD_INDEX;

        uint256 totalShares = _rewardSharesTotal();
        uint256 released = _vestedAmount(_selfBalance(token) - lastBalance);
        lastVestAt = block.timestamp;

        if (totalShares != 0) index += released.divDown(totalShares);

        rewardState[token] = RewardState({index: index.Uint128(), lastBalance: (lastBalance + released).Uint128()});
        indexes[0] = index;
    }

    function _vestedAmount(uint256 unvestedAmount) internal view returns (uint256) {
        uint256 duration = vestingDuration;
        uint256 elapsed = block.timestamp - lastVestAt;

        if (elapsed >= duration) return unvestedAmount;
        return (unvestedAmount * elapsed) / duration;
    }

    function _redeemExternalReward() internal virtual override {}

    function _getRewardTokens() internal view virtual override returns (address[] memory) {
        return ArrayLib.create(rewardToken);
    }

    function unvestedRewards() external view returns (uint256) {
        return _selfBalance(rewardToken) - rewardState[rewardToken].lastBalance;
    }

    /*///////////////////////////////////////////////////////////////
                                OWNER
    //////////////////////////////////////////////////////////////*/

    function setVestingDuration(uint256 newDuration) external onlyOwner {
        _updateRewardIndex();
        _setVestingDuration(newDuration);
    }

    function _setVestingDuration(uint256 newDuration) internal {
        if (newDuration == 0) revert ZeroVestingDuration();
        vestingDuration = newDuration;
        emit VestingDurationUpdated(newDuration);
    }

    /*///////////////////////////////////////////////////////////////
                               MISC
    //////////////////////////////////////////////////////////////*/

    function getTokensIn() public view virtual override returns (address[] memory) {
        return ArrayLib.create(yieldToken);
    }

    function getTokensOut() public view virtual override returns (address[] memory) {
        return ArrayLib.create(yieldToken);
    }

    function isValidTokenIn(address token) public view virtual override returns (bool) {
        return token == yieldToken;
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
        return (AssetType.TOKEN, yieldToken, IERC20Metadata(yieldToken).decimals());
    }
}
