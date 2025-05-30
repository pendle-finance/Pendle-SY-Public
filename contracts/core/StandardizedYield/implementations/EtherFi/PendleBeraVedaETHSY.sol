// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.23;

import "./PendleVedaBaseSY.sol";

contract PendleBeraVedaETHSY is PendleVedaBaseSY {
    // solhint-disable immutable-vars-naming
    // solhint-disable const-name-snakecase
    // solhint-disable ordering

    address public constant liquidBeraETH = 0x83599937c2C9bEA0E0E8ac096c6f32e86486b410;
    address public constant teller = 0xd445C65e4821dbD4ed0114eCDF6325c69faD7653;

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant WEETH = 0xCd5fE23C85820F7B72D0926FC9b05b43E359b7ee;
    address public constant EETH = 0x35fA164735182de50811E8e2E824cFb9B6118ac2;
    address public constant WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;

    constructor() PendleVedaBaseSY(liquidBeraETH, teller, 1 ether) {}

    function approveAllForTeller() external {
        _safeApproveInf(WETH, liquidBeraETH);
        _safeApproveInf(WEETH, liquidBeraETH);
        _safeApproveInf(EETH, liquidBeraETH);
        _safeApproveInf(WSTETH, liquidBeraETH);
    }

    function exchangeRate() public view virtual override returns (uint256) {
        return IVedaAccountant(vedaAccountant).getRateInQuoteSafe(WETH);
    }

    function isValidTokenIn(address token) public pure override returns (bool) {
        return token == liquidBeraETH || token == WETH || token == WEETH || token == EETH || token == WSTETH;
    }

    function getTokensIn() public pure override returns (address[] memory res) {
        return ArrayLib.create(liquidBeraETH, WETH, WEETH, EETH, WSTETH);
    }

    function assetInfo()
        external
        pure
        override
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.TOKEN, NATIVE, 18);
    }
}
