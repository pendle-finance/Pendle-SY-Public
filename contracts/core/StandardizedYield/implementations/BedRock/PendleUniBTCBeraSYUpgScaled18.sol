// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../../SYBaseUpg.sol";
import "../../../../interfaces/Bedrock/IBedrockUniBTCVault.sol";
import "../../../../interfaces/IPDecimalsWrapperFactory.sol";

import "../../../misc/ScaledTokenMath.sol";

contract PendleUniBTCBeraSYUpgScaled18 is SYBaseUpg, ScaledTokenMath {
    address public constant VAULT = 0xE0240d05Ae9eF703E2b71F3f4Eb326ea1888DEa3;
    address public constant UNIBTC = 0xC3827A4BC8224ee2D116637023b124CED6db6e90;
    address public constant WBTC = 0x0555E30da8f98308EdB960aa94C0Db47230d2B9c;
    address public constant DECIMALS_WRAPPER_FACTORY = 0x992EC6A490A4B7f256bd59E63746951D98B29Be9;

    address public immutable wrappedAsset = IPDecimalsWrapperFactory(DECIMALS_WRAPPER_FACTORY).getOrCreate(UNIBTC, 18);

    constructor()
        SYBaseUpg(UNIBTC)
        ScaledTokenMath(UNIBTC, IPDecimalsWrapperFactory(DECIMALS_WRAPPER_FACTORY).getOrCreate(UNIBTC, 18))
    {
        _disableInitializers();
    }

    function initialize() external initializer {
        _safeApproveInf(WBTC, VAULT);
        __SYBaseUpg_init("SY Bedrock uniBTC scaled18", "SY-uniBTC-scaled18");
    }

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn != UNIBTC) {
            uint256 preBalance = _selfBalance(UNIBTC);
            IBedrockUniBTCVault(VAULT).mint(tokenIn, amountDeposited);
            return _selfBalance(UNIBTC) - preBalance;
        }
        return amountDeposited; /// (WBTC & FBTC both have 8 decimals)
    }

    function _redeem(
        address receiver,
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal override returns (uint256) {
        _transferOut(UNIBTC, receiver, amountSharesToRedeem);
        return amountSharesToRedeem;
    }

    function exchangeRate() public view virtual override returns (uint256 res) {
        return _toScaled(PMath.ONE); // exchange rate returns amount of asset equivalent to 1 share, asset is scaled, so using toScaled
    }

    function _previewDeposit(
        address /*tokenIn*/,
        uint256 amountTokenToDeposit
    ) internal view virtual override returns (uint256 /*amountSharesOut*/) {
        return amountTokenToDeposit;
    }

    function _previewRedeem(
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal view virtual override returns (uint256 /*amountTokenOut*/) {
        return amountSharesToRedeem;
    }

    function getTokensIn() public pure override returns (address[] memory res) {
        return ArrayLib.create(WBTC, UNIBTC);
    }

    function getTokensOut() public pure override returns (address[] memory res) {
        return ArrayLib.create(UNIBTC);
    }

    function isValidTokenIn(address token) public pure override returns (bool) {
        return token == WBTC || token == UNIBTC;
    }

    function isValidTokenOut(address token) public pure override returns (bool) {
        return token == UNIBTC;
    }

    function assetInfo() external view returns (AssetType assetType, address assetAddress, uint8 assetDecimals) {
        return (AssetType.TOKEN, wrappedAsset, IERC20Metadata(wrappedAsset).decimals());
    }
}
