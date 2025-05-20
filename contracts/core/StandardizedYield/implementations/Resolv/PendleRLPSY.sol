// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../PendleERC20SYUpg.sol";
import "../../../../interfaces/IPExchangeRateOracle.sol";

contract PendleRLPSY is PendleERC20SYUpg {
    using PMath for uint256;

    address public constant RLP = 0xc7AB90c2Ea9271EFB31f5fA2843Eeb4B331eaFA0;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public immutable exchangeRateOracle;

    constructor(address _exchangeRateOracle) PendleERC20SYUpg(RLP) {
        exchangeRateOracle = _exchangeRateOracle;
    }

    function exchangeRate() public view virtual override returns (uint256 res) {
        return IPExchangeRateOracle(exchangeRateOracle).getExchangeRate();
    }

    function assetInfo()
        external
        view
        virtual
        override
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.TOKEN, USDC, IERC20Metadata(USDC).decimals());
    }
}
