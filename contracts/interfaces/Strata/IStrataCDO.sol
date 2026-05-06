// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IStrataCDO {
    enum TExitMode {
        Dynamic,
        Fee,
        AssetsLock,
        SharesLock,
        ERC4626
    }

    function strategy() external view returns (address);
    function isJrt(address tranche) external view returns (bool);
    function calculateExitMode(
        address tranche,
        address owner
    ) external view returns (TExitMode mode, uint256 feeBps, uint32 cooldownSeconds);
}
