// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.23;

import "../EtherFi/PendleVedaBaseSYV2.sol";
import "../../../misc/TokenWithSupplyCapUpg.sol";
contract PendleHwHLPSY is PendleVedaBaseSYV2, TokenWithSupplyCapUpg {
    // solhint-disable immutable-vars-naming
    // solhint-disable const-name-snakecase
    // solhint-disable ordering

    using PMath for uint256;

    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant USDE = 0x4c9EDD5852cd905f086C759E8383e09bff1E68B3;

    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant teller = 0xfA9D7D4709716b90Cd5013fD88fB17AEEDd24Bc4;

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
    }

    function exchangeRate() public view virtual override returns (uint256) {
        return IVedaAccountant(vedaAccountant).getRateSafe() * (10**12);
    }

    function isValidTokenIn(address token) public view override returns (bool) {
        return token == USDT || token == USDE || token == yieldToken;
    }

    function getTokensIn() public view override returns (address[] memory res) {
        return ArrayLib.create(USDT, USDE, yieldToken);
    }

    function assetInfo()
        external
        pure
        override
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.TOKEN, USDC, 6);
    }

    function getAbsoluteTotalSupply() external view returns (uint256) {
        return totalSupply();
    }

    function _afterTokenTransfer(address from, address, uint256) internal view override {
        if (from != address(0)) {
            _checkSupplyCap(totalSupply());
        }
    }
}
