// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../../v2/SYBaseUpgV2.sol";
import "../../../../interfaces/Strata/IStrataTranche.sol";
import "../../../../interfaces/Strata/IStrataCDO.sol";
import "../../../../interfaces/Strata/IStrataSNUSDStrategy.sol";
import "../../../../interfaces/Neutrl/IInstantUnstaking.sol";

contract PendleStrataNUSDTrancheSY is SYBaseUpgV2 {
    address public immutable strata;
    bool public immutable isJrt;
    address public immutable nusd;
    address public immutable sNusd;
    address public immutable instantUnstaking;

    constructor(address _strata, address _nusd, address _sNusd, address _instantUnstaking) SYBaseUpgV2(_strata) {
        strata = _strata;
        nusd = _nusd;
        sNusd = _sNusd;
        instantUnstaking = _instantUnstaking;

        isJrt = IStrataCDO(IStrataTranche(strata).cdo()).isJrt(strata);
    }

    function initialize(string memory name_, string memory symbol_, address _owner) external initializer {
        __SYBaseUpgV2_init(name_, symbol_, _owner);
        _safeApproveInf(nusd, strata);
        _safeApproveInf(sNusd, strata);
    }

    function exchangeRate() external view override returns (uint256) {
        return IStrataTranche(strata).convertToAssets(PMath.ONE);
    }

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 amountSharesOut) {
        if (tokenIn == strata) {
            return amountDeposited;
        }
        return IStrataTranche(strata).deposit(tokenIn, amountDeposited, address(this));
    }

    function _redeem(
        address receiver,
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal override returns (uint256) {
        if (tokenOut == strata) {
            _transferOut(strata, receiver, amountSharesToRedeem);
            return amountSharesToRedeem;
        } else {
            // redeem sNusd from ERC4626
            uint256 amountTokenOut = IStrataTranche(strata).redeem(
                sNusd,
                amountSharesToRedeem,
                address(this),
                address(this)
            );

            if (tokenOut == nusd) {
                _safeApprove(sNusd, instantUnstaking, amountTokenOut);
                amountTokenOut = IInstantUnstaking(instantUnstaking).instantUnstake(amountTokenOut, 0);
            }

            _transferOut(tokenOut, receiver, amountTokenOut);
            return amountTokenOut;
        }
    }

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == strata) {
            return amountTokenToDeposit;
        }

        return IStrataTranche(strata).previewDeposit(tokenIn, amountTokenToDeposit);
    }

    function _previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal view virtual override returns (uint256 /*amountTokenOut*/) {
        if (tokenOut == strata) {
            return amountSharesToRedeem;
        } else {
            uint256 amountTokenOut = IStrataTranche(strata).previewRedeem(sNusd, amountSharesToRedeem);

            if (tokenOut == nusd) {
                (amountTokenOut, ) = IInstantUnstaking(instantUnstaking).quoteInstantUnstake(
                    address(this),
                    amountTokenOut
                );
            }

            return amountTokenOut;
        }
    }

    function getTokensIn() public view virtual override returns (address[] memory res) {
        return ArrayLib.create(strata, nusd, sNusd);
    }

    function getTokensOut() public view virtual override returns (address[] memory res) {
        if (_isSNUSDValidTokenOut()) return ArrayLib.create(strata, sNusd, nusd);
        return ArrayLib.create(strata);
    }

    function isValidTokenIn(address token) public view virtual override returns (bool) {
        return token == strata || token == nusd || token == sNusd;
    }

    function isValidTokenOut(address token) public view virtual override returns (bool) {
        return token == strata || ((token == sNusd || token == nusd) && _isSNUSDValidTokenOut());
    }

    function assetInfo() external view returns (AssetType assetType, address assetAddress, uint8 assetDecimals) {
        return (AssetType.TOKEN, nusd, 18);
    }

    function _isSNUSDValidTokenOut() internal view returns (bool) {
        address strategy = IStrataCDO(IStrataTranche(strata).cdo()).strategy();

        uint256 cooldownTime = isJrt
            ? IStrataSNUSDStrategy(strategy).sNUSDCooldownJrt()
            : IStrataSNUSDStrategy(strategy).sNUSDCooldownSrt();
        return cooldownTime == 0;
    }
}
