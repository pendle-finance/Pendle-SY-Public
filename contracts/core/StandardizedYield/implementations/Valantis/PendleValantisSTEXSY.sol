// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../v2/SYBaseUpgV2.sol";
import "../../../../interfaces/Valantis/IStexAmm.sol";
import "../../../../interfaces/Valantis/IStexLens.sol";
import "../../../../interfaces/Valantis/IStexSovereignPool.sol";

contract PendleValantisSTEXSY is SYBaseUpgV2 {
    using PMath for uint256;

    IStexLens public immutable stexLens;
    IStexAmm public immutable stexAmm;
    IStexSovereignPool public immutable sovereignPool;
    address public immutable asset;

    constructor(address _stexLens, address _stexAmm) SYBaseUpgV2(_stexAmm) {
        stexLens = IStexLens(_stexLens);
        stexAmm = IStexAmm(_stexAmm);
        sovereignPool = IStexSovereignPool(stexAmm.pool());
        asset = stexAmm.token1();

        require(sovereignPool.isToken0Rebase(), "PendleValatisSTEXSY: token0 must be a rebase token");
        require(sovereignPool.isToken1Rebase(), "PendleValatisSTEXSY: token1 must be a rebase token");
    }

    function initialize(string memory name_, string memory symbol_, address _owner) external initializer {
        __SYBaseUpgV2_init(name_, symbol_, _owner);
        _safeApproveInf(asset, address(stexAmm));
    }

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 amountSharesOut) {
        if (tokenIn == yieldToken) {
            return amountDeposited;
        }

        amountSharesOut = stexAmm.deposit(amountDeposited, 0, type(uint256).max, address(this));
    }

    function _redeem(
        address receiver,
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal virtual override returns (uint256 amountTokenOut) {
        if (tokenOut == yieldToken) {
            _transferOut(yieldToken, receiver, amountSharesToRedeem);
            return amountSharesToRedeem;
        }

        (, amountTokenOut) = stexAmm.withdraw(amountSharesToRedeem, 0, 0, type(uint256).max, receiver, false, true);
    }

    function exchangeRate() external view virtual override returns (uint256) {
        (uint256 totalAssetValue, uint256 totalSupply) = _getStexData();
        if (totalSupply == 0) return PMath.ONE;
        return totalAssetValue.divDown(totalSupply);
    }

    function _getStexData() internal view returns (uint256 totalAssetValue, uint256 totalSupply) {
        totalAssetValue = stexLens.getTotalValueToken1(address(stexAmm));
        totalSupply = stexAmm.totalSupply();
    }

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view virtual override returns (uint256 amountSharesOut) {
        if (tokenIn == yieldToken) {
            return amountTokenToDeposit;
        }

        amountSharesOut = stexLens.getSharesForDeposit(address(stexAmm), amountTokenToDeposit);
    }

    function _previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal view virtual override returns (uint256 amountTokenOut) {
        if (tokenOut == yieldToken) {
            return amountSharesToRedeem;
        }

        (, amountTokenOut) = stexLens.getAmountsForWithdraw(address(stexAmm), amountSharesToRedeem, true);
    }

    function getTokensIn() public view virtual override returns (address[] memory res) {
        return ArrayLib.create(asset, yieldToken);
    }

    function getTokensOut() public view virtual override returns (address[] memory res) {
        return ArrayLib.create(asset, yieldToken);
    }

    function isValidTokenIn(address token) public view virtual override returns (bool) {
        return token == asset || token == yieldToken;
    }

    function isValidTokenOut(address token) public view virtual override returns (bool) {
        return token == asset || token == yieldToken;
    }

    function assetInfo() external view returns (AssetType assetType, address assetAddress, uint8 assetDecimals) {
        return (AssetType.TOKEN, asset, IERC20Metadata(asset).decimals());
    }
}
