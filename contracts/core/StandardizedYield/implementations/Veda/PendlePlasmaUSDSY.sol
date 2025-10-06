// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.23;

import "../EtherFi/PendleVedaBaseSYV2.sol";

contract PendlePlasmaUSDSY is PendleVedaBaseSYV2 {
    address public constant USDT0 = 0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb;
    address public constant PLASMA_USD = 0xd1074E0AE85610dDBA0147e29eBe0D8E5873a000;
    address public constant teller = 0x4E7d2186eB8B75fBDcA867761636637E05BaeF1E;

    constructor() PendleVedaBaseSYV2(PLASMA_USD, teller, 10 ** 6, true) {}

    function initialize(string memory _name, string memory _symbol, address _owner) external override initializer {
        __SYBaseUpgV2_init(_name, _symbol, _owner);
        _safeApproveInf(USDT0, PLASMA_USD);
    }

    function exchangeRate() public view override returns (uint256) {
        return IVedaAccountant(vedaAccountant).getRateSafe() * (10 ** 12);
    }

    function getTokensIn() public pure override returns (address[] memory res) {
        return ArrayLib.create(USDT0, PLASMA_USD);
    }

    function isValidTokenIn(address token) public view virtual override returns (bool) {
        return token == USDT0 || token == PLASMA_USD;
    }

    function assetInfo()
        external
        pure
        override
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.TOKEN, USDT0, 6);
    }
}
