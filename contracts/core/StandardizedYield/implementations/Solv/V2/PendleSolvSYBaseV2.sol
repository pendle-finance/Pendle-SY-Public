// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../../SYBaseUpg.sol";
import "../../../../../interfaces/Solv/ISolvRouterV2.sol";
import "../../../../../interfaces/Solv/ISolvOpenFundMarket.sol";
import "../../../../../interfaces/Solv/ISolvERC3525.sol";
import "../../../../../interfaces/Solv/ISolvOracle.sol";

abstract contract PendleSolvSYBaseV2 is SYBaseUpg {
    event SetNewExchangeRateOracle(address oracle);

    // solhint-disable immutable-vars-naming
    address public immutable solvRouterV2;
    address public immutable SOLV_OPEN_FUND_MARKET;

    constructor(address _solvRouterV2, address _yieldToken) SYBaseUpg(_yieldToken) {
        solvRouterV2 = _solvRouterV2;
        SOLV_OPEN_FUND_MARKET = ISolvRouterV2(_solvRouterV2).openFundMarket();
    }

    function _deposit(address tokenIn, uint256 amountDeposited) internal virtual override returns (uint256) {
        if (tokenIn == yieldToken) {
            return amountDeposited;
        }
        return ISolvRouterV2(solvRouterV2).deposit(yieldToken, tokenIn, amountDeposited, 0, type(uint64).max);
    }

    function _redeem(
        address receiver,
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal virtual override returns (uint256) {
        _transferOut(yieldToken, receiver, amountSharesToRedeem);
        return amountSharesToRedeem;
    }

    /*///////////////////////////////////////////////////////////////
                               EXCHANGE-RATE
    //////////////////////////////////////////////////////////////*/

    function exchangeRate() public view virtual override returns (uint256) {
        return PMath.ONE;
    }

    function _previewRedeem(
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal view virtual override returns (uint256 amountTokenOut) {
        return amountSharesToRedeem;
    }

    function getTokensOut() public view virtual override returns (address[] memory) {
        return ArrayLib.create(yieldToken);
    }

    function isValidTokenOut(address token) public view virtual override returns (bool) {
        return token == yieldToken;
    }

    function assetInfo()
        external
        view
        virtual
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.TOKEN, yieldToken, IERC20Metadata(yieldToken).decimals());
    }

    function _previewSolvConvert(bytes32 poolId, uint256 amountIn) internal view returns (uint256) {
        ISolvOpenFundMarket.PoolInfo memory info = ISolvOpenFundMarket(SOLV_OPEN_FUND_MARKET).poolInfos(poolId);
        uint256 numerator = 10 ** ISolvERC3525(info.poolSFTInfo.openFundShare).valueDecimals();
        (uint256 price, ) = ISolvOracle(info.navOracle).getSubscribeNav(poolId, block.timestamp);
        return (amountIn * numerator) / price;
    }
}
