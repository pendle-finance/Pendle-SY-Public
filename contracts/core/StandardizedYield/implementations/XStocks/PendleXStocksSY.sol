// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../v2/SYBaseUpgV2.sol";
import "../../../../interfaces/XStocks/IXStocks.sol";

contract PendleXStocksSY is SYBaseUpgV2 {
    address public immutable xStocks;

    constructor(address _xStocks) SYBaseUpgV2(_xStocks) {
        xStocks = _xStocks;
    }

    function initialize(string memory name_, string memory symbol_, address _owner) external virtual initializer {
        __SYBaseUpgV2_init(name_, symbol_, _owner);
    }

    function _deposit(
        address /*tokenIn*/,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 amountSharesOut) {
        amountSharesOut = IXStocks(xStocks).getSharesByUnderlyingAmount(amountDeposited);
    }

    function _redeem(
        address receiver,
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal virtual override returns (uint256 amountTokenOut) {
        amountTokenOut = IXStocks(xStocks).getUnderlyingAmountByShares(amountSharesToRedeem);
        _transferOut(tokenOut, receiver, amountTokenOut);
    }

    function exchangeRate() external view virtual override returns (uint256 res) {
        return IXStocks(xStocks).getUnderlyingAmountByShares(PMath.ONE);
    }

    function _previewDeposit(
        address /*tokenIn*/,
        uint256 amountTokenToDeposit
    ) internal view virtual override returns (uint256 amountSharesOut) {
        return IXStocks(xStocks).getSharesByUnderlyingAmount(amountTokenToDeposit);
    }

    function _previewRedeem(
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal view virtual override returns (uint256 amountTokenOut) {
        return IXStocks(xStocks).getUnderlyingAmountByShares(amountSharesToRedeem);
    }

    function getTokensIn() public view virtual override returns (address[] memory res) {
        res = new address[](1);
        res[0] = xStocks;
    }

    function getTokensOut() public view virtual override returns (address[] memory res) {
        res = new address[](1);
        res[0] = xStocks;
    }

    function isValidTokenIn(address token) public view virtual override returns (bool) {
        return token == xStocks;
    }

    function isValidTokenOut(address token) public view virtual override returns (bool) {
        return token == xStocks;
    }

    function pricingInfo() external view virtual override returns (address refToken, bool refStrictlyEqual) {
        return (yieldToken, false);
    }

    function assetInfo()
        external
        view
        virtual
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.TOKEN, xStocks, IERC20Metadata(xStocks).decimals());
    }
}
