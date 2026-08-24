// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../v2/SYBaseUpgV2.sol";
import "../../../../interfaces/XStocks/IXStocks.sol";

contract PendleXStocksSY is SYBaseUpgV2 {
    using PMath for uint256;

    event YieldCollected(uint256 rate, uint256 amount);

    address public immutable xStocks;
    address public immutable yieldReceiver;

    uint256 internal _watermarkRateStored;
    uint256[100] private __gap;

    constructor(address _xStocks, address _yieldReceiver) SYBaseUpgV2(_xStocks) {
        xStocks = _xStocks;
        yieldReceiver = _yieldReceiver;
    }

    function initialize(string memory name_, string memory symbol_, address _owner) external initializer {
        __SYBaseUpgV2_init(name_, symbol_, _owner);
    }

    function _deposit(
        address /*tokenIn*/,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 amountSharesOut) {
        (uint256 currentRate, uint256 watermarkRate) = updateRates();
        amountSharesOut = (amountDeposited * watermarkRate) / currentRate;
    }

    function _redeem(
        address receiver,
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal virtual override returns (uint256 amountTokenOut) {
        (uint256 currentRate, uint256 watermarkRate) = updateRates();
        amountTokenOut = (amountSharesToRedeem * currentRate) / watermarkRate;
        _transferOut(yieldToken, receiver, amountTokenOut);
    }

    function collectUnderlyingYield() external onlyOwner returns (uint256 collectedYield) {
        (uint256 currentRate, uint256 watermarkRate) = updateRates();

        uint256 totalAssetBacking = PMath.rawDivUp(totalSupply() * currentRate, watermarkRate);
        uint256 totalAssetOwned = _selfBalance(xStocks);

        if (totalAssetOwned > totalAssetBacking) {
            collectedYield = totalAssetOwned - totalAssetBacking;
            _transferOut(xStocks, yieldReceiver, collectedYield);
            emit YieldCollected(currentRate, collectedYield);
        }
    }

    function getRates() public view returns (uint256 currentRate, uint256 watermarkRate) {
        currentRate = IXStocks(xStocks).getUnderlyingAmountByShares(PMath.ONE);
        watermarkRate = PMath.max(_watermarkRateStored, currentRate);
    }

    function updateRates() public returns (uint256 currentRate, uint256 watermarkRate) {
        (currentRate, watermarkRate) = getRates();
        _watermarkRateStored = watermarkRate;
    }

    function exchangeRate() external view virtual override returns (uint256) {
        (uint256 currentRate, uint256 watermarkRate) = getRates();
        return currentRate.divDown(watermarkRate);
    }

    function _previewDeposit(
        address /*tokenIn*/,
        uint256 amountTokenToDeposit
    ) internal view virtual override returns (uint256 amountSharesOut) {
        (uint256 currentRate, uint256 watermarkRate) = getRates();
        amountSharesOut = (amountTokenToDeposit * watermarkRate) / currentRate;
    }

    function _previewRedeem(
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal view virtual override returns (uint256 amountTokenOut) {
        (uint256 currentRate, uint256 watermarkRate) = getRates();
        amountTokenOut = (amountSharesToRedeem * currentRate) / watermarkRate;
    }

    function getTokensIn() public view virtual override returns (address[] memory) {
        return ArrayLib.create(xStocks);
    }

    function getTokensOut() public view virtual override returns (address[] memory) {
        return ArrayLib.create(xStocks);
    }

    function isValidTokenIn(address token) public view virtual override returns (bool) {
        return token == xStocks;
    }

    function isValidTokenOut(address token) public view virtual override returns (bool) {
        return token == xStocks;
    }

    function pricingInfo() external view virtual override returns (address refToken, bool refStrictlyEqual) {
        return (xStocks, false);
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
