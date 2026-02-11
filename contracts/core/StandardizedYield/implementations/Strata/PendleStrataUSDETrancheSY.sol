// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../../v2/SYBaseUpgV2.sol";
import "../../../../interfaces/Strata/IStrataTranche.sol";
import "../../../../interfaces/Strata/IStrataCDO.sol";
import "../../../../interfaces/Strata/IStrataSUSDEStrategy.sol";

contract PendleStrataUSDETrancheSY is SYBaseUpgV2 {
    address public immutable strata;
    bool public immutable isJrt;
    address public immutable usde;
    address public immutable sUSDe;

    constructor(address _strata, address _usde, address _sUSDe) SYBaseUpgV2(_strata) {
        strata = _strata;
        usde = _usde;
        sUSDe = _sUSDe;

        isJrt = IStrataCDO(IStrataTranche(strata).cdo()).isJrt(strata);
    }

    function initialize(string memory name_, string memory symbol_, address _owner) external initializer {
        __SYBaseUpgV2_init(name_, symbol_, _owner);
        _safeApproveInf(usde, strata);
        _safeApproveInf(sUSDe, strata);
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
        return ArrayLib.create(strata, usde, sUSDe);
    }

    function getTokensOut() public view virtual override returns (address[] memory res) {
        if (_isSUSDEValidTokenOut()) return ArrayLib.create(strata, sUSDe);
        return ArrayLib.create(strata);
    }

    function isValidTokenIn(address token) public view virtual override returns (bool) {
        return token == strata || token == usde || token == sUSDe;
    }

    function isValidTokenOut(address token) public view virtual override returns (bool) {
        return token == strata || (token == sUSDe && _isSUSDEValidTokenOut());
    }

    function assetInfo() external view returns (AssetType assetType, address assetAddress, uint8 assetDecimals) {
        return (AssetType.TOKEN, usde, 18);
    }

    function _isSUSDEValidTokenOut() internal view returns (bool) {
        address strategy = IStrataCDO(IStrataTranche(strata).cdo()).strategy();

        uint256 cooldownTime = isJrt
            ? IStrataSUSDEStrategy(strategy).sUSDeCooldownJrt()
            : IStrataSUSDEStrategy(strategy).sUSDeCooldownSrt();
        return cooldownTime == 0;
    }
}
