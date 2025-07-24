// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../v2/SYBaseUpgV2.sol";
import "../../../../interfaces/Kinetic/IKineticStakingAccountant.sol";
import "../../../../interfaces/Kinetic/IKineticStakingManager.sol";

contract PendleKineticKHYPESY is SYBaseUpgV2 {
    using PMath for uint256;

    address public constant KHYPE = 0xfD739d4e423301CE9385c1fb8850539D657C296D;
    address public constant STAKING_MANAGER = 0x393D0B87Ed38fc779FD9611144aE649BA6082109;
    address public constant STAKING_ACCOUNTANT = 0x9209648Ec9D448EF57116B73A2f081835643dc7A;
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
        IKineticStakingManager(STAKING_MANAGER).stake{value: _truncAmount(amountDeposited)}();
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
        return IKineticStakingAccountant(STAKING_ACCOUNTANT).kHYPEToHYPE(1 ether);
    }

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == NATIVE) {
            return IKineticStakingAccountant(STAKING_ACCOUNTANT).HYPEToKHYPE(amountTokenToDeposit);
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
}
