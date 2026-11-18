// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.28;

import "./PendleCommonERC20SYUpg.sol";
import "../../../../interfaces/IPExchangeRateOracle.sol";

contract PendleCommonERC20WithOracleSYUpg is PendleCommonERC20SYUpg {
    address public immutable assetScaled18;
    address public immutable exchangeRateOracle;

    uint256[100] private __gap;

    constructor(
        address _erc20,
        address _underlyingAsset,
        address _exchangeRateOracle,
        address _decimalsWrapperFactory,
        address _offchainRewardManager
    ) PendleCommonERC20SYUpg(_erc20, _decimalsWrapperFactory, _offchainRewardManager) {
        assetScaled18 = DecimalsWrapperLib.scaled18(_decimalsWrapperFactory, _underlyingAsset);
        exchangeRateOracle = _exchangeRateOracle;
    }

    /*///////////////////////////////////////////////////////////////
                               EXCHANGE-RATE
    //////////////////////////////////////////////////////////////*/

    /// @dev oracle must return yieldToken -> assetScaled18, 18 decimals
    function exchangeRate() public view override returns (uint256) {
        return IPExchangeRateOracle(exchangeRateOracle).getExchangeRate();
    }

    /*///////////////////////////////////////////////////////////////
                        MISC FUNCTIONS FOR METADATA
    //////////////////////////////////////////////////////////////*/

    function assetInfo() external view virtual override returns (AssetType, address, uint8) {
        return (AssetType.TOKEN, assetScaled18, 18);
    }
}
