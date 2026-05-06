// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./base/PendleStrataTrancheBaseSY.sol";
import "../../../../interfaces/Strata/IStrataSUSDATStrategy.sol";

contract PendleStrataUSDatTrancheSY is PendleStrataTrancheBaseSY {
    constructor(address _strata, address _usdat, address _sUsdat) PendleStrataTrancheBaseSY(_strata, _usdat, _sUsdat) {}

    function _isStakedAssetValidTokenOut() internal view override returns (bool) {
        address strategy = IStrataCDO(IStrataTranche(strata).cdo()).strategy();

        uint256 cooldownTime = isJrt
            ? IStrataSUSDATStrategy(strategy).sUSDatCooldownJrt()
            : IStrataSUSDATStrategy(strategy).sUSDatCooldownSrt();

        if (cooldownTime != 0) return false;

        (IStrataCDO.TExitMode exitMode, , uint32 cooldownSec) = IStrataCDO(IStrataTranche(strata).cdo())
            .calculateExitMode(strata, address(this));
        return exitMode != IStrataCDO.TExitMode.SharesLock && cooldownSec == 0;
    }
}
