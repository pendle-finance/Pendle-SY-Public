// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IKinetiqStakingAccountant {
    function kHYPEToHYPE(uint256 kHYPEAmount) external view returns (uint256);
    function HYPEToKHYPE(uint256 HYPEAmount) external view returns (uint256);
}
