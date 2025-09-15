// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../PendleERC20SYUpgV2.sol";
import "../../../../interfaces/Gauntlet/IGauntletPriceAndFeeCalculator.sol";

contract PendleGauntletGTUSDASY is PendleERC20SYUpgV2 {
    address public constant PRICE_FEE_CALCULATOR = 0x69dD4D44eed6BbC33B8A0bdFe17897Ab9044372e;
    address public constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address public constant gtUSDa = 0x000000000001CdB57E58Fa75Fe420a0f4D6640D5;

    uint8 internal constant FLOOR_ROUNDING = 0;

    constructor() PendleERC20SYUpgV2(gtUSDa) {}

    function exchangeRate() public view override returns (uint256 res) {
        return
            IGauntletPriceAndFeeCalculator(PRICE_FEE_CALCULATOR).convertUnitsToTokenIfActive(
                gtUSDa,
                USDC,
                10 ** 18,
                FLOOR_ROUNDING
            );
    }

    function assetInfo()
        external
        pure
        override
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.TOKEN, USDC, 6);
    }
}
