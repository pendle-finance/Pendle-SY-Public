// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../PendleERC20SYUpg.sol";
import "../../../../interfaces/IPExchangeRateOracle.sol";

contract PendleRLPSY is PendleERC20SYUpg {
    using PMath for uint256;

    address public constant RLP = 0x4956b52aE2fF65D74CA2d61207523288e4528f96;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant rlpPriceStorage = 0xaE2364579D6cB4Bbd6695846C1D595cA9AF3574d;

    address public immutable exchangeRateOracle;

    constructor(address _exchangeRateOracle) PendleERC20SYUpg(RLP) {
        exchangeRateOracle = _exchangeRateOracle;
    }

    function exchangeRate() public view virtual override returns (uint256 res) {
        (uint256 price, ) = IRlpPriceStorage(rlpPriceStorage).lastPrice();
        return price;
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

interface IRlpPriceStorage {
    function lastPrice() external view returns (uint256 price, uint256 timestamp);
}
