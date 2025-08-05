// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.23;

import "../EtherFi/PendleVedaBaseSYV2.sol";
import "../../../misc/TokenWithSupplyCapUpg.sol";
contract PendleHwHLPHypeSY is PendleVedaBaseSYV2, TokenWithSupplyCapUpg {
    // solhint-disable immutable-vars-naming
    // solhint-disable const-name-snakecase
    // solhint-disable ordering

    using PMath for uint256;

    address public constant USDT = 0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb;
    address public constant USDE = 0x5d3a1Ff2b6BAb83b63cd9AD0787074081a52ef34;
    address public constant USDHL = 0xb50A96253aBDF803D85efcDce07Ad8becBc52BD5;

    address public constant teller = 0xfEFF6652e393Df46f88CDAcF5cd05DBbb227214e;

    constructor() PendleVedaBaseSYV2(IVedaTeller(teller).vault(), teller, 10 ** 6, false) {}

    function initialize(
        string memory _name,
        string memory _symbol,
        address _owner,
        uint256 _initialSupplyCap
    ) external virtual initializer {
        __SYBaseUpgV2_init(_name, _symbol, _owner);
        __tokenWithSupplyCap_init(_initialSupplyCap);
        _safeApproveInf(USDT, yieldToken);
        _safeApproveInf(USDE, yieldToken);
        _safeApproveInf(USDHL, yieldToken);
    }

    function exchangeRate() public view virtual override returns (uint256) {
        return IVedaAccountant(vedaAccountant).getRateSafe() * (10 ** 12);
    }

    function isValidTokenIn(address token) public view override returns (bool) {
        return token == USDT || token == USDE || token == USDHL || token == yieldToken;
    }

    function getTokensIn() public view override returns (address[] memory res) {
        return ArrayLib.create(USDT, USDE, USDHL, yieldToken);
    }

    function assetInfo()
        external
        pure
        override
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.TOKEN, USDT, 6);
    }

    function getAbsoluteTotalSupply() external view returns (uint256) {
        return totalSupply();
    }

    function _afterTokenTransfer(address from, address, uint256) internal view override {
        if (from != address(0)) {
            return;
        }
        _checkSupplyCap(totalSupply());
    }
}
