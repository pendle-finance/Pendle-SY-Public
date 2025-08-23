// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "../../v2/SYBaseUpgV2.sol";
import "../../../../interfaces/Terminal/ITerminalDepositVault.sol";
import "../../../../interfaces/Terminal/ITerminalRedemptionVault.sol";
import "../../../../interfaces/Terminal/ITerminalFeed.sol";
import "../../../../interfaces/IPDecimalsWrapperFactory.sol";

contract PendleTerminalSYScaled18 is SYBaseUpgV2 {
    address public immutable terminalDepositVault;
    address public immutable terminalRedemptionVault;

    address public immutable vaultTokenIn;
    address public immutable vaultTokenOut;

    address public immutable asset;
    address public immutable assetScaled;

    bytes32 public constant REFERRAL_ID = 0x0000000000000000000000000000000000000000000000000000000000000021;

    constructor(
        address _terminalDepositVault,
        address _terminalRedemptionVault,
        address _vaultTokenIn,
        address _vaultTokenOut,
        address _asset,
        address _decimalsWrapperFactory
    ) SYBaseUpgV2(ITerminalDepositVault(_terminalDepositVault).mToken()) {
        terminalDepositVault = _terminalDepositVault;
        terminalRedemptionVault = _terminalRedemptionVault;
        vaultTokenIn = _vaultTokenIn;
        vaultTokenOut = _vaultTokenOut;
        asset = _asset;

        assert(asset == vaultTokenIn); // accurate assumption for now

        if (IERC20Metadata(asset).decimals() < 18) {
            assetScaled = IPDecimalsWrapperFactory(_decimalsWrapperFactory).getOrCreate(_asset, 18);
        } else {
            assetScaled = asset;
        }
    }

    function initialize(string memory _name, string memory _symbol, address _owner) external virtual initializer {
        __SYBaseUpgV2_init(_name, _symbol, _owner);
        _safeApproveInf(vaultTokenIn, terminalDepositVault);
    }

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == yieldToken) {
            return amountDeposited;
        }

        uint256 lastBalance = _selfBalance(yieldToken);
        ITerminalDepositVault(terminalDepositVault).depositInstant(
            vaultTokenIn,
            _toBase18(amountDeposited, vaultTokenIn),
            0,
            REFERRAL_ID
        );
        return _selfBalance(yieldToken) - lastBalance;
    }

    function _redeem(
        address receiver,
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal virtual override returns (uint256 amountTokenOut) {
        if (yieldToken == tokenOut) {
            amountTokenOut = amountSharesToRedeem;
        } else {
            uint256 lastBalance = _selfBalance(tokenOut);
            ITerminalRedemptionVault(terminalRedemptionVault).redeemInstant(tokenOut, amountSharesToRedeem, 0);
            amountTokenOut = _selfBalance(tokenOut) - lastBalance;
        }
        _transferOut(tokenOut, receiver, amountTokenOut);
    }

    function exchangeRate() public view virtual override returns (uint256) {
        // [SHOULD BE approx 1] As discussed by Terminal team, the exchange stays at 1 unless facing blackswan event
        // Asset is scaled to 18, and mToken is also 18. So this rate returned here matches its decimals
        return PMath.divDown(_getRate(terminalDepositVault, yieldToken), _getRate(terminalDepositVault, vaultTokenIn));
    }

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == yieldToken) {
            return amountTokenToDeposit;
        }

        // [NOTE]:
        // - MTokens are always 18 decimals
        // - Fees are currently 0 and will not be configured in the future (confirmed by Terminal team)
        return
            (_toBase18(amountTokenToDeposit, tokenIn) * _getRate(terminalDepositVault, vaultTokenIn)) /
            _getRate(terminalDepositVault, yieldToken);
    }

    function _previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal view virtual override returns (uint256 /*amountTokenOut*/) {
        if (tokenOut == yieldToken) {
            return amountSharesToRedeem;
        }

        // [NOTE]:
        // - MTokens are always 18 decimals
        // - Fees are currently 0 and will not be configured in the future (confirmed by Terminal team)
        return
            _fromBase18(
                (amountSharesToRedeem * _getRate(terminalRedemptionVault, yieldToken)) /
                    _getRate(terminalRedemptionVault, tokenOut),
                tokenOut
            );
    }

    function getTokensIn() public view virtual override returns (address[] memory res) {
        return ArrayLib.create(vaultTokenIn, yieldToken);
    }

    function getTokensOut() public view virtual override returns (address[] memory res) {
        return ArrayLib.create(vaultTokenOut, yieldToken);
    }

    function isValidTokenIn(address token) public view virtual override returns (bool) {
        return token == vaultTokenIn || token == yieldToken;
    }

    function isValidTokenOut(address token) public view virtual override returns (bool) {
        return token == vaultTokenOut || token == yieldToken;
    }

    function assetInfo()
        external
        view
        virtual
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.TOKEN, assetScaled, IERC20Metadata(assetScaled).decimals());
    }

    function _getRate(address vault, address token) internal view returns (uint256 rate) {
        if (token == yieldToken) {
            address feed = ITerminalDepositVault(vault).mTokenDataFeed();
            return ITerminalFeed(feed).getDataInBase18();
        }

        ITerminalDepositVault.TokenConfig memory config = ITerminalDepositVault(vault).tokensConfig(token);
        if (config.stable) {
            return PMath.ONE;
        }
        return ITerminalFeed(config.dataFeed).getDataInBase18();
    }

    function _toBase18(uint256 amount, address token) internal view returns (uint256 truncatedAmount) {
        return (amount * (10 ** 18)) / (10 ** IERC20Metadata(token).decimals());
    }

    function _fromBase18(uint256 amount, address token) internal view returns (uint256 truncatedAmount) {
        return (amount * (10 ** IERC20Metadata(token).decimals())) / (10 ** 18);
    }
}
