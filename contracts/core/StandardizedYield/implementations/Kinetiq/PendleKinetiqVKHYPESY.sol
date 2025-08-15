// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../EtherFi/PendleVedaBaseSYV2.sol";
import "../../../../interfaces/IPTokenWithSupplyCap.sol";

contract PendleKinetiqVKHYPESY is PendleVedaBaseSYV2, IPTokenWithSupplyCap {
    error SupplyCapExceeded(uint256 totalSupply, uint256 supplyCap);

    address public constant vkHYPE = 0x9BA2EDc44E0A4632EB4723E81d4142353e1bB160;
    address public constant teller = 0x29C0C36eD3788F1549b6a1fd78F40c51F0f73158;

    address public constant WHYPE = 0x5555555555555555555555555555555555555555;
    address public constant KHYPE = 0xfD739d4e423301CE9385c1fb8850539D657C296D;

    constructor() PendleVedaBaseSYV2(vkHYPE, teller, 10 ** 18, true) {}

    function initialize(string memory _name, string memory _symbol, address _owner) external override initializer {
        __SYBaseUpgV2_init(_name, _symbol, _owner);
        _safeApproveInf(WHYPE, vkHYPE);
        _safeApproveInf(KHYPE, vkHYPE);
    }

    function exchangeRate() public view override returns (uint256 res) {
        return IVedaAccountant(vedaAccountant).getRateSafe();
    }

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == yieldToken) {
            return amountDeposited;
        }
        return IVedaTeller(teller).bulkDeposit(tokenIn, amountDeposited, 0, address(this));
    }

    function _previewDeposit(address tokenIn, uint256 amountTokenToDeposit)
        internal
        view
        virtual
        override
        returns (uint256 amountSharesOut)
    {
        amountSharesOut = super._previewDeposit(tokenIn, amountTokenToDeposit);

        if (tokenIn == yieldToken) {
            return amountSharesOut;
        }

        uint112 _supplyCap = IVedaTeller(teller).depositCap();
        if (_supplyCap != type(uint112).max) {
            uint256 _newSupply = IERC20(vkHYPE).totalSupply() + amountSharesOut;
            if (_newSupply > _supplyCap) {
                revert SupplyCapExceeded(_newSupply, _supplyCap);
            }
        }
    }

    function getTokensIn() public pure override returns (address[] memory res) {
        return ArrayLib.create(vkHYPE, WHYPE, KHYPE);
    }

    function isValidTokenIn(address token) public pure override returns (bool) {
        return token == vkHYPE || token == WHYPE || token == KHYPE;
    }

    function getAbsoluteSupplyCap() external view returns (uint256) {
        uint112 cap = IVedaTeller(teller).depositCap();
        if (cap == type(uint112).max) return type(uint256).max;
        return cap;
    }

    function getAbsoluteTotalSupply() external view returns (uint256) {
        return IERC20(vkHYPE).totalSupply();
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
