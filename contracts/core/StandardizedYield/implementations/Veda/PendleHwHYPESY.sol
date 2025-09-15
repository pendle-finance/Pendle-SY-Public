// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.23;

import "../EtherFi/PendleVedaBaseSYV2.sol";

contract PendleHwHYPESY is PendleVedaBaseSYV2 {
    address public constant WHYPE = 0x5555555555555555555555555555555555555555;
    address public constant HWHYPE = 0x4DE03cA1F02591B717495cfA19913aD56a2f5858;
    address public constant teller = 0x70cb1a1888aFee738344Dd879d818E1f369b3Dd5;

    constructor() PendleVedaBaseSYV2(HWHYPE, teller, 10 ** 18, false) {}

    function initialize(string memory _name, string memory _symbol, address _owner) external override initializer {
        __SYBaseUpgV2_init(_name, _symbol, _owner);
        _safeApproveInf(WHYPE, HWHYPE);
    }

    function exchangeRate() public view override returns (uint256) {
        return IVedaAccountant(vedaAccountant).getRateSafe();
    }

    function isValidTokenIn(address token) public pure override returns (bool) {
        return token == WHYPE || token == HWHYPE;
    }

    function getTokensIn() public pure override returns (address[] memory res) {
        return ArrayLib.create(WHYPE, HWHYPE);
    }

    function assetInfo()
        external
        pure
        override
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.TOKEN, WHYPE, 18);
    }
}
