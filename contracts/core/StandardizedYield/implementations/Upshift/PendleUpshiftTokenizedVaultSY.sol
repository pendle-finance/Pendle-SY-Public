// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../v2/SYBaseUpgV2.sol";
import "../../../misc/TokenWithSupplyCapUpg.sol";
import "../../../../interfaces/Upshift/ITokenizedVault.sol";

contract PendleUpshiftTokenizedVaultSY is SYBaseUpgV2, TokenWithSupplyCapUpg {
    using ArrayLib for address[];

    error MaxDepositAmountReached();
    error DepositCapReached();
    error WithdrawalLimitReached();
    error AmountTooLow();

    address public immutable tokenizedVault;
    address public immutable asset;

    uint256 internal immutable decimalOffsets;

    constructor(address _yieldToken, address _tokenizedVault) SYBaseUpgV2(_yieldToken) {
        tokenizedVault = _tokenizedVault;
        decimalOffsets = 10 ** (18 - IERC20Metadata(_yieldToken).decimals());
        asset = ITokenizedVault(tokenizedVault).asset();
    }

    function initialize(string memory name_, string memory symbol_, address _owner) external initializer {
        __SYBaseUpgV2_init(name_, symbol_, _owner);
        __tokenWithSupplyCap_init(type(uint256).max);
    }

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 amountSharesOut) {
        if (tokenIn == yieldToken) {
            return amountDeposited;
        }

        _safeApproveInf(tokenIn, tokenizedVault);
        amountSharesOut = ITokenizedVault(tokenizedVault).deposit(tokenIn, amountDeposited, address(this));
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

        uint256 preBalance = _selfBalance(tokenOut);
        ITokenizedVault(tokenizedVault).instantRedeem(amountSharesToRedeem, address(this));
        amountTokenOut = _selfBalance(tokenOut) - preBalance;

        _transferOut(tokenOut, receiver, amountTokenOut);
    }

    function exchangeRate() external view virtual override returns (uint256 res) {
        return ITokenizedVault(tokenizedVault).getSharePrice() * decimalOffsets;
    }

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == yieldToken) {
            return amountTokenToDeposit;
        }

        (uint256 shares, uint256 depositAmountInAsset) = ITokenizedVault(tokenizedVault).previewDeposit(
            tokenIn,
            amountTokenToDeposit
        );

        if (depositAmountInAsset > ITokenizedVault(tokenizedVault).maxDepositAmount()) revert MaxDepositAmountReached();

        uint256 totalAssets = depositAmountInAsset + ITokenizedVault(tokenizedVault).getTotalAssets();

        if (totalAssets > ITokenizedVault(tokenizedVault).depositCap()) revert DepositCapReached();

        return shares;
    }

    function _previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal view virtual override returns (uint256 /*amountTokenOut*/) {
        if (tokenOut == yieldToken) {
            return amountSharesToRedeem;
        }

        (uint256 assetsAmount, uint256 assetsAfterFee) = ITokenizedVault(tokenizedVault).previewRedemption(
            amountSharesToRedeem,
            true
        );

        if (assetsAmount > ITokenizedVault(tokenizedVault).maxWithdrawalAmount()) revert WithdrawalLimitReached();
        if (assetsAfterFee < 1) revert AmountTooLow();

        return assetsAfterFee;
    }

    function getTokensIn() public view virtual override returns (address[] memory res) {
        return
            ArrayLib.create(yieldToken, asset).merge(
                ITokenizedVault(tokenizedVault).assetsWhitelistAddress().getWhitelistedAssets()
            );
    }

    function getTokensOut() public view virtual override returns (address[] memory res) {
        return ArrayLib.create(yieldToken, asset);
    }

    function isValidTokenIn(address token) public view virtual override returns (bool) {
        return
            token == yieldToken ||
            token == asset ||
            ITokenizedVault(tokenizedVault).assetsWhitelistAddress().isWhitelisted(token);
    }

    function isValidTokenOut(address token) public view virtual override returns (bool) {
        return token == yieldToken || token == asset;
    }

    function assetInfo() external view returns (AssetType assetType, address assetAddress, uint8 assetDecimals) {
        return (AssetType.TOKEN, asset, IERC20Metadata(asset).decimals());
    }

    /*///////////////////////////////////////////////////////////////
                               SUPPLY-CAP
    //////////////////////////////////////////////////////////////*/

    function getAbsoluteTotalSupply() external view returns (uint256) {
        return totalSupply();
    }

    function _afterTokenTransfer(address from, address, uint256) internal view override {
        if (from != address(0)) {
            return;
        }
        _checkSupplyCap(totalSupply());
    }
}
