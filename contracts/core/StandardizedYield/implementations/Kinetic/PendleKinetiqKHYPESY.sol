// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../v2/SYBaseUpgV2.sol";
import "../../../../interfaces/Kinetiq/IKinetiqStakingAccountant.sol";
import "../../../../interfaces/Kinetiq/IKinetiqStakingManager.sol";
import "../../../../interfaces/Kinetiq/IKinetiqValidatorManager.sol";
import "../../../../interfaces/IPTokenWithSupplyCap.sol";

contract PendleKinetiqKHYPESY is SYBaseUpgV2, IPTokenWithSupplyCap {
    using PMath for uint256;

    error KinetiqMinStakeNotMet();
    error KinetiqMaxStakeExceeded();

    address public constant KHYPE = 0xfD739d4e423301CE9385c1fb8850539D657C296D;
    address public constant STAKING_MANAGER = 0x393D0B87Ed38fc779FD9611144aE649BA6082109;
    address public constant STAKING_ACCOUNTANT = 0x9209648Ec9D448EF57116B73A2f081835643dc7A;
    address public constant VALIDATOR_MANAGER = 0x4b797A93DfC3D18Cf98B7322a2b142FA8007508f;
    uint256 public constant DEPOSIT_DENOM = 1e10;

    constructor() SYBaseUpgV2(KHYPE) {}

    function initialize(address _owner) external virtual initializer {
        __SYBaseUpgV2_init("SY Kinetiq Staked HYPE", "SY-kHYPE", _owner);
    }

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == yieldToken) {
            return amountDeposited;
        }

        uint256 preBalance = _selfBalance(yieldToken);
        // Hot path, ignoring min, max check
        IKinetiqStakingManager(STAKING_MANAGER).stake{value: _truncAmount(amountDeposited)}();
        return _selfBalance(yieldToken) - preBalance;
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
        return IKinetiqStakingAccountant(STAKING_ACCOUNTANT).kHYPEToHYPE(1 ether);
    }

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == NATIVE) {
            amountTokenToDeposit = _truncAmount(amountTokenToDeposit);
            _validateStakeAmount(amountTokenToDeposit);
            return IKinetiqStakingAccountant(STAKING_ACCOUNTANT).HYPEToKHYPE(amountTokenToDeposit);
        }
        return amountTokenToDeposit;
    }

    function _previewRedeem(
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal view virtual override returns (uint256 /*amountTokenOut*/) {
        return amountSharesToRedeem;
    }

    function getTokensIn() public view virtual override returns (address[] memory res) {
        return ArrayLib.create(NATIVE, yieldToken);
    }

    function getTokensOut() public view virtual override returns (address[] memory res) {
        return ArrayLib.create(yieldToken);
    }

    function isValidTokenIn(address token) public view virtual override returns (bool) {
        return token == NATIVE || token == yieldToken;
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
        return (AssetType.TOKEN, NATIVE, 18);
    }

    function _truncAmount(uint256 amount) internal pure virtual returns (uint256) {
        return amount - (amount % DEPOSIT_DENOM);
    }

    function _validateStakeAmount(uint256 amount) internal view virtual {
        uint256 minStake = IKinetiqStakingManager(STAKING_MANAGER).minStakeAmount();
        uint256 maxStake = IKinetiqStakingManager(STAKING_MANAGER).maxStakeAmount();
        if (amount < minStake) {
            revert KinetiqMinStakeNotMet();
        }
        if (maxStake > 0 && amount > maxStake) {
            revert KinetiqMaxStakeExceeded();
        }
    }

    function getAbsoluteSupplyCap() external view returns (uint256) {
        return IKinetiqStakingManager(STAKING_MANAGER).stakingLimit();
    }

    function getAbsoluteTotalSupply() external view returns (uint256) {
        return
            IKinetiqStakingManager(STAKING_MANAGER).totalStaked() +
            IKinetiqValidatorManager(VALIDATOR_MANAGER).totalRewards() -
            IKinetiqStakingManager(STAKING_MANAGER).totalClaimed();
    }
}
