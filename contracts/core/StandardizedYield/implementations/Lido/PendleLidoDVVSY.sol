// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../v2/SYBaseUpgV2.sol";
import "../../../../interfaces/IERC4626.sol";
import "../../../../interfaces/IWstETH.sol";
import "../../../../interfaces/IStETH.sol";
import "../../../../interfaces/Lido/IWhitelistedEthWrapper.sol";
import "../../../misc/MerklRewardAbstract__NoStorage.sol";

contract PendleLidoDVVSY is SYBaseUpgV2, MerklRewardAbstract__NoStorage {
    using PMath for uint256;

    address public immutable WETH;
    address public immutable WSTETH;
    address public immutable STETH;
    address public immutable whitelistedEthWrapper;

    constructor(
        address _yieldToken,
        address _whitelistedEthWrapper,
        address _offchainRewardManager
    ) SYBaseUpgV2(_yieldToken) MerklRewardAbstract__NoStorage(_offchainRewardManager) {
        whitelistedEthWrapper = _whitelistedEthWrapper;
        WETH = IWhitelistedEthWrapper(_whitelistedEthWrapper).WETH();
        WSTETH = IWhitelistedEthWrapper(_whitelistedEthWrapper).wstETH();
        STETH = IWstETH(WSTETH).stETH();
    }

    function initialize(string memory name_, string memory symbol_, address _owner) external initializer {
        __SYBaseUpgV2_init(name_, symbol_, _owner);
        _safeApproveInf(WETH, whitelistedEthWrapper);
    }

    function _deposit(address tokenIn, uint256 amountDeposited) internal override returns (uint256 amountSharesOut) {
        if (tokenIn == yieldToken) {
            return amountDeposited;
        }

        amountSharesOut = IWhitelistedEthWrapper(whitelistedEthWrapper).deposit(
            tokenIn,
            amountDeposited,
            yieldToken,
            address(this),
            address(this)
        );
    }

    function _redeem(
        address receiver,
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal override returns (uint256 /*amountTokenOut*/) {
        if (tokenOut == yieldToken) {
            _transferOut(tokenOut, receiver, amountSharesToRedeem);
            return amountSharesToRedeem;
        }

        return IERC4626(yieldToken).redeem(amountSharesToRedeem, receiver, address(this));
    }

    function exchangeRate() external view override returns (uint256 res) {
        return IERC4626(yieldToken).convertToAssets(PMath.ONE).mulDown(IStETH(STETH).getPooledEthByShares(PMath.ONE));
    }

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view override returns (uint256 amountSharesOut) {
        if (tokenIn == yieldToken) {
            return amountTokenToDeposit;
        }

        uint256 amountWstETH = IStETH(STETH).getSharesByPooledEth(amountTokenToDeposit);
        return IERC4626(yieldToken).previewDeposit(amountWstETH);
    }

    function _previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal view override returns (uint256 amountTokenOut) {
        if (tokenOut == yieldToken) {
            return amountSharesToRedeem;
        }

        return IERC4626(yieldToken).previewRedeem(amountSharesToRedeem);
    }

    function getTokensIn() public view override returns (address[] memory res) {
        return ArrayLib.create(yieldToken, WETH);
    }

    function getTokensOut() public view override returns (address[] memory res) {
        return ArrayLib.create(yieldToken, WSTETH);
    }

    function isValidTokenIn(address token) public view override returns (bool) {
        return token == yieldToken || token == WETH;
    }

    function isValidTokenOut(address token) public view override returns (bool) {
        return token == yieldToken || token == WSTETH;
    }

    function assetInfo() external view returns (AssetType assetType, address assetAddress, uint8 assetDecimals) {
        return (AssetType.TOKEN, STETH, IERC20Metadata(STETH).decimals());
    }
}
