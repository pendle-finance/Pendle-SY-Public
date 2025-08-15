// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../NucleusBoring/PendleNucleusBoringVaultBaseSY.sol";

contract PendleLoopingLHYPESY is PendleNucleusBoringVaultBaseSY {
    address public constant LHYPE = 0x5748ae796AE46A4F1348a1693de4b50560485562;
    address public constant WHYPE = 0x5555555555555555555555555555555555555555;
    address public constant KHYPE = 0xfD739d4e423301CE9385c1fb8850539D657C296D;
    address public constant STHYPE = 0xfFaa4a3D97fE9107Cef8a3F48c069F577Ff76cC1;

    address public constant teller = 0xFd83C1ca0c04e096d129275126fade1dC45BF4F0;
    address public constant depositor = 0x6e358dd1204c3fb1D24e569DF0899f48faBE5337;

    constructor() PendleNucleusBoringVaultBaseSY(LHYPE, teller, depositor, WHYPE) {}

    function PENDLE_COMMUNITY_CODE() internal pure override returns (bytes memory) {
        return "pendle";
    }

    function initialize(string memory name_, string memory symbol_, address _owner) external initializer {
        __SYBaseUpgV2_init(name_, symbol_, _owner);
        _safeApproveInf(WHYPE, depositor);
        _safeApproveInf(KHYPE, depositor);
        _safeApproveInf(STHYPE, depositor);
    }

    function getTokensIn() public pure override returns (address[] memory res) {
        return ArrayLib.create(WHYPE, KHYPE, STHYPE, LHYPE);
    }

    function isValidTokenIn(address token) public pure override returns (bool) {
        return token == WHYPE || token == KHYPE || token == STHYPE || token == LHYPE;
    }
}
