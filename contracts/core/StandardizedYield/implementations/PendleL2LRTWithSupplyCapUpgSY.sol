// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../v2/SYBaseUpgV2.sol";
import "../../../interfaces/IPExchangeRateOracle.sol";
import {TokenWithSupplyCapUpg} from "../../misc/TokenWithSupplyCapUpg.sol";

contract PendleL2LRTWithSupplyCapUpgSY is SYBaseUpgV2, TokenWithSupplyCapUpg {
    using PMath for int256;

    address public exchangeRateOracle;
    address internal immutable underlyingAssetOnEthAddr;
    uint8 internal immutable underlyingAssetOnEthDecimals;

    uint256[100] private __gap;

    constructor(
        address _token,
        address _underlyingAssetOnEthAddr,
        uint8 _underlyingAssetOnEthDecimals
    ) SYBaseUpgV2(_token) {
        underlyingAssetOnEthAddr = _underlyingAssetOnEthAddr;
        underlyingAssetOnEthDecimals = _underlyingAssetOnEthDecimals;
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        address _exchangeRateOracle,
        address _owner
    ) external initializer {
        __SYBaseUpgV2_init(_name, _symbol, _owner);
        __tokenWithSupplyCap_init(type(uint256).max);
        exchangeRateOracle = _exchangeRateOracle;
    }

    function setExchangeRateOracle(address newOracle) external onlyOwner {
        exchangeRateOracle = newOracle;
    }

    /*///////////////////////////////////////////////////////////////
                    DEPOSIT/REDEEM USING BASE TOKENS
    //////////////////////////////////////////////////////////////*/

    function _deposit(address, uint256 amountDeposited) internal pure override returns (uint256 /*amountSharesOut*/) {
        return amountDeposited;
    }

    function _redeem(
        address receiver,
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal override returns (uint256 /*amountTokenOut*/) {
        _transferOut(tokenOut, receiver, amountSharesToRedeem);
        return amountSharesToRedeem;
    }

    /*///////////////////////////////////////////////////////////////
                               EXCHANGE-RATE
    //////////////////////////////////////////////////////////////*/

    function exchangeRate() public view override returns (uint256) {
        return IPExchangeRateOracle(exchangeRateOracle).getExchangeRate();
    }

    /*///////////////////////////////////////////////////////////////
                MISC FUNCTIONS FOR METADATA
    //////////////////////////////////////////////////////////////*/

    function _previewDeposit(
        address,
        uint256 amountTokenToDeposit
    ) internal pure override returns (uint256 /*amountSharesOut*/) {
        return amountTokenToDeposit;
    }

    function _previewRedeem(
        address,
        uint256 amountSharesToRedeem
    ) internal pure override returns (uint256 /*amountTokenOut*/) {
        return amountSharesToRedeem;
    }

    function getTokensIn() public view override returns (address[] memory res) {
        return ArrayLib.create(yieldToken);
    }

    function getTokensOut() public view override returns (address[] memory res) {
        return ArrayLib.create(yieldToken);
    }

    function isValidTokenIn(address token) public view override returns (bool) {
        return token == yieldToken;
    }

    function isValidTokenOut(address token) public view override returns (bool) {
        return token == yieldToken;
    }

    function assetInfo() external view returns (AssetType assetType, address assetAddress, uint8 assetDecimals) {
        return (AssetType.TOKEN, underlyingAssetOnEthAddr, underlyingAssetOnEthDecimals);
    }

    /*///////////////////////////////////////////////////////////////
                               SUPPLY CAP
    //////////////////////////////////////////////////////////////*/

    function getAbsoluteTotalSupply() external view virtual override returns (uint256) {
        return totalSupply();
    }

    function _afterTokenTransfer(address from, address, uint256) internal view override {
        if (from != address(0)) {
            return;
        }
        _checkSupplyCap(totalSupply());
    }
}
