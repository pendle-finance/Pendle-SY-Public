// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../../v2/SYBaseUpgV2.sol";
import "../../../../interfaces/Strata/IStrataTranche.sol";
import "../../../../interfaces/Strata/IStrataCDO.sol";
import "../../../../interfaces/Strata/IStrataSNUSDStrategy.sol";

contract PendleStrataNUSDTrancheSY is SYBaseUpgV2 {
    address public immutable strata;
    bool public immutable isJrt;
    address public immutable nusd;
    address public immutable sNusd;

    constructor(address _strata, address _nusd, address _sNusd) SYBaseUpgV2(_strata) {
        strata = _strata;
        nusd = _nusd;
        sNusd = _sNusd;

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
        }
        return IStrataTranche(strata).redeem(tokenOut, amountSharesToRedeem, receiver, address(this));
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
        }

        return IStrataTranche(strata).previewRedeem(tokenOut, amountSharesToRedeem);
    }

    function getTokensIn() public view virtual override returns (address[] memory res) {
        return ArrayLib.create(strata, nusd, sNusd);
    }

    function getTokensOut() public view virtual override returns (address[] memory res) {
        if (_isSNUSDValidTokenOut()) return ArrayLib.create(strata, sNusd);
        return ArrayLib.create(strata);
    }

    function isValidTokenIn(address token) public view virtual override returns (bool) {
        return token == strata || token == nusd || token == sNusd;
    }

    function isValidTokenOut(address token) public view virtual override returns (bool) {
        return token == strata || (token == sNusd && _isSNUSDValidTokenOut());
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
