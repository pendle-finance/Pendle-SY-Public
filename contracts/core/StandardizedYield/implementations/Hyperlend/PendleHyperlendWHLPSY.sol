// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../NucleusBoring/PendleNucleusBoringVaultBaseSY.sol";

contract PendleHyperlendWHLPSY is PendleNucleusBoringVaultBaseSY {
    address public constant WHLP = 0x1359b05241cA5076c9F59605214f4F84114c0dE8;
    address public constant USDHL = 0xb50A96253aBDF803D85efcDce07Ad8becBc52BD5;

    address public constant teller = 0x9781E42b4f3cB55Ba837F9579D17970d9efccB34;
    address public constant depositor = 0x340C9f6159ABc2bdfCC0E2b9Fe91D739006b41c1;

    constructor() PendleNucleusBoringVaultBaseSY(WHLP, teller, depositor, USDHL) {}

    function PENDLE_COMMUNITY_CODE() internal pure override returns (bytes memory) {
        return "pendle";
    }

    function initialize(string memory name_, string memory symbol_, address _owner) external initializer {
        __SYBaseUpgV2_init(name_, symbol_, _owner);
        _safeApproveInf(USDHL, depositor);
    }

    function getTokensIn() public pure override returns (address[] memory res) {
        return ArrayLib.create(USDHL, WHLP);
    }

    function isValidTokenIn(address token) public pure override returns (bool) {
        return token == USDHL || token == WHLP;
    }
}
