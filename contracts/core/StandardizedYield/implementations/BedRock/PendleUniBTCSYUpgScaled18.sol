// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../../SYBaseUpg.sol";
import "../../../../interfaces/Bedrock/IBedrockUniBTCVault.sol";
import "../../../../interfaces/IPDecimalsWrapperFactory.sol";
import "../../../../interfaces/IPDecimalsWrapper.sol";
import "../../../../interfaces/IStandardizedYieldExtended.sol";

contract PendleUniBTCSYUpgScaled18 is SYBaseUpg, IStandardizedYieldExtended {
    address public constant VAULT = 0x047D41F2544B7F63A8e991aF2068a363d210d6Da;
    address public constant UNIBTC = 0x004E9C3EF86bc1ca1f0bB5C7662861Ee93350568;
    address public constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address public constant FBTC = 0xC96dE26018A54D51c097160568752c4E3BD6C364;
    address public constant CBBTC = 0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf;
    address public constant DECIMALS_WRAPPER_FACTORY = 0x992EC6A490A4B7f256bd59E63746951D98B29Be9;

    constructor() SYBaseUpg(IPDecimalsWrapperFactory(DECIMALS_WRAPPER_FACTORY).getOrCreate(UNIBTC, 18)) {
        _disableInitializers();
    }

    function initialize() external initializer {
        _safeApproveInf(WBTC, VAULT);
        _safeApproveInf(FBTC, VAULT);
        _safeApproveInf(CBBTC, VAULT);
        _safeApproveInf(UNIBTC, yieldToken);
        __SYBaseUpg_init("SY Bedrock uniBTC scaled18", "SY-uniBTC-scaled18");
    }

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn != UNIBTC) {
            uint256 preBalance = _selfBalance(UNIBTC);
            IBedrockUniBTCVault(VAULT).mint(tokenIn, amountDeposited);
            (tokenIn, amountDeposited) = (UNIBTC, _selfBalance(UNIBTC) - preBalance);
        }
        return IPDecimalsWrapper(yieldToken).wrap(amountDeposited);
    }

    function _redeem(
        address receiver,
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal override returns (uint256) {
        uint256 amountOut = IPDecimalsWrapper(yieldToken).unwrap(amountSharesToRedeem);
        _transferOut(UNIBTC, receiver, amountOut);
        return amountOut;
    }

    function exchangeRate() public view virtual override returns (uint256 res) {
        return PMath.ONE;
    }

    function _previewDeposit(
        address /*tokenIn*/,
        uint256 amountTokenToDeposit
    ) internal view virtual override returns (uint256 /*amountSharesOut*/) {
        return IPDecimalsWrapper(yieldToken).rawToWrapped(amountTokenToDeposit);
    }

    function _previewRedeem(
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal view virtual override returns (uint256 /*amountTokenOut*/) {
        return IPDecimalsWrapper(yieldToken).wrappedToRaw(amountSharesToRedeem);
    }

    function getTokensIn() public pure override returns (address[] memory res) {
        return ArrayLib.create(WBTC, FBTC, UNIBTC, CBBTC);
    }

    function getTokensOut() public pure override returns (address[] memory res) {
        return ArrayLib.create(UNIBTC);
    }

    function isValidTokenIn(address token) public pure override returns (bool) {
        return token == WBTC || token == FBTC || token == UNIBTC || token == CBBTC;
    }

    function isValidTokenOut(address token) public pure override returns (bool) {
        return token == UNIBTC;
    }

    function assetInfo() external view returns (AssetType assetType, address assetAddress, uint8 assetDecimals) {
        return (AssetType.TOKEN, yieldToken, IERC20Metadata(yieldToken).decimals());
    }

    function pricingInfo() external pure returns (address refToken, bool refStrictlyEqual) {
        return (UNIBTC, true);
    }
}
