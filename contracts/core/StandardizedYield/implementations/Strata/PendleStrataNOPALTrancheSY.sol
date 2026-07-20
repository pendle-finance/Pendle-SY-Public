// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./base/PendleStrataTrancheBaseSY.sol";
import "../../../../interfaces/Strata/IStrataNOPALStrategy.sol";

contract PendleStrataNOPALTrancheSY is PendleStrataTrancheBaseSY {
    constructor(address _strata, address _usdc, address _nOpal) PendleStrataTrancheBaseSY(_strata, _usdc, _nOpal) {}

    function _isStakedAssetValidTokenOut() internal view override returns (bool) {
        address strategy = IStrataCDO(IStrataTranche(strata).cdo()).strategy();

        uint256 cooldownTime = isJrt
            ? IStrataNOPALStrategy(strategy).nOpalCooldownJrt()
            : IStrataNOPALStrategy(strategy).nOpalCooldownSrt();

        if (cooldownTime != 0) return false;

        (IStrataCDO.TExitMode exitMode, , uint32 cooldownSec) = IStrataCDO(IStrataTranche(strata).cdo())
            .calculateExitMode(strata, address(this));
        return exitMode != IStrataCDO.TExitMode.SharesLock && cooldownSec == 0;
    }

    function getTokensIn() public view override returns (address[] memory res) {
        return ArrayLib.create(strata, stakedAsset);
    }

    function isValidTokenIn(address token) public view override returns (bool) {
        return token == strata || token == stakedAsset;
    }
}
