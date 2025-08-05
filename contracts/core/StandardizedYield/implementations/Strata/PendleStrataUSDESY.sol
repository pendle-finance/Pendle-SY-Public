// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "../../v2/SYBaseUpgV2.sol";
import "../../../../interfaces/Strata/IStrataMetaVault.sol";
import "../../../../interfaces/IERC4626.sol";

contract PendleStrataUSDESY is SYBaseUpgV2 {
    address public constant STRATA_META_VAULT = 0xA62B204099277762d1669d283732dCc1B3AA96CE;
    address public constant USDE = 0x4c9EDD5852cd905f086C759E8383e09bff1E68B3;
    address public constant EUSDE = 0x90D2af7d622ca3141efA4d8f1F24d86E5974Cc8F;

    constructor() SYBaseUpgV2(STRATA_META_VAULT) {}

    function initialize(address _owner) external virtual initializer {
        __SYBaseUpgV2_init("SY Strata Pre-deposit Receipt Token", "SY-pUSDe", _owner);
        _safeApproveInf(USDE, STRATA_META_VAULT);
        _safeApproveInf(EUSDE, STRATA_META_VAULT);
    }

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == STRATA_META_VAULT) {
            return amountDeposited;
        } else {
            return IStrataMetaVault(STRATA_META_VAULT).deposit(tokenIn, amountDeposited, address(this));
        }
    }

    function _redeem(
        address receiver,
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal virtual override returns (uint256 amountTokenOut) {
        if (tokenOut == STRATA_META_VAULT) {
            amountTokenOut = amountSharesToRedeem;
            _transferOut(STRATA_META_VAULT, receiver, amountTokenOut);
        } else {
            amountTokenOut = IStrataMetaVault(STRATA_META_VAULT).redeem(
                tokenOut,
                amountSharesToRedeem,
                receiver,
                address(this)
            );
        }
    }

    function exchangeRate() public view virtual override returns (uint256) {
        return IERC4626(STRATA_META_VAULT).convertToAssets(PMath.ONE);
    }

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == STRATA_META_VAULT) {
            return amountTokenToDeposit;
        } else if (tokenIn == EUSDE) {
            // EUSDE ---redeem---> USDE --- deposit ---> SY Strata Meta Vault
            return IERC4626(STRATA_META_VAULT).previewDeposit(IERC4626(EUSDE).previewRedeem(amountTokenToDeposit));
        } else {
            return IERC4626(STRATA_META_VAULT).previewDeposit(amountTokenToDeposit);
        }
    }

    function _previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal view virtual override returns (uint256 /*amountTokenOut*/) {
        if (tokenOut == STRATA_META_VAULT) {
            return amountSharesToRedeem;
        } else if (tokenOut == USDE) {
            // SY Strata Meta Vault ---redeem---> USDE --- deposit ---> EUSDE
            return IERC4626(STRATA_META_VAULT).previewRedeem(amountSharesToRedeem);
        } else {
            return IERC4626(EUSDE).previewWithdraw(IERC4626(STRATA_META_VAULT).previewRedeem(amountSharesToRedeem));
        }
    }

    function getTokensIn() public view virtual override returns (address[] memory res) {
        return ArrayLib.create(USDE, EUSDE, STRATA_META_VAULT);
    }

    function getTokensOut() public view virtual override returns (address[] memory res) {
        if (_isPreYieldPhase()) {
            return ArrayLib.create(USDE, EUSDE, STRATA_META_VAULT);
        } else {
            return ArrayLib.create(STRATA_META_VAULT);
        }
    }

    function isValidTokenIn(address token) public view virtual override returns (bool) {
        return token == USDE || token == EUSDE || token == STRATA_META_VAULT;
    }

    function isValidTokenOut(address token) public view virtual override returns (bool) {
        if (_isPreYieldPhase()) {
            return token == USDE || token == EUSDE || token == STRATA_META_VAULT;
        } else {
            return token == STRATA_META_VAULT;
        }
    }

    function assetInfo()
        external
        view
        virtual
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.TOKEN, USDE, IERC20Metadata(USDE).decimals());
    }

    function _isPreYieldPhase() internal view returns (bool) {
        return IStrataMetaVault(STRATA_META_VAULT).currentPhase() != IStrataMetaVault.PreDepositPhase.YieldPhase;
    }
}
