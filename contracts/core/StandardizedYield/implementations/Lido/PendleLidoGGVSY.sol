// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../EtherFi/PendleVedaBaseSYV2.sol";
import "../../../misc/MerklRewardAbstract__NoStorage.sol";

contract PendleLidoGGVSY is PendleVedaBaseSYV2, MerklRewardAbstract__NoStorage {
    address public constant GGV = 0xef417FCE1883c6653E7dC6AF7c6F85CCDE84Aa09;
    address public constant teller = 0x4C74ccA483A278Bcb90Aea3f8F565e56202D82B2;

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant STETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address public constant WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;

    constructor(
        address _offchainRewardManager
    ) PendleVedaBaseSYV2(GGV, teller, 10 ** 18, true) MerklRewardAbstract__NoStorage(_offchainRewardManager) {}

    function initialize(string memory _name, string memory _symbol, address _owner) external override initializer {
        __SYBaseUpgV2_init(_name, _symbol, _owner);
        _safeApproveInf(WETH, GGV);
        _safeApproveInf(STETH, GGV);
        _safeApproveInf(WSTETH, GGV);
    }

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == yieldToken) {
            return amountDeposited;
        }

        return IVedaTeller(vedaTeller).bulkDeposit(tokenIn, amountDeposited, 0, address(this));
    }

    function exchangeRate() public view override returns (uint256) {
        return IVedaAccountant(vedaAccountant).getRateSafe();
    }

    function getTokensIn() public pure override returns (address[] memory res) {
        return ArrayLib.create(GGV, WETH, STETH, WSTETH);
    }

    function isValidTokenIn(address token) public pure override returns (bool) {
        return token == GGV || token == WETH || token == STETH || token == WSTETH;
    }

    function assetInfo()
        external
        pure
        override
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.TOKEN, WETH, 18);
    }
}
