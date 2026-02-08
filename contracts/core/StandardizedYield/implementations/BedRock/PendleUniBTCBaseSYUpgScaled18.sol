// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../../SYBaseUpg.sol";
import "../../../../interfaces/Bedrock/IBedrockUniBTCVault.sol";
import "../../../../interfaces/IPDecimalsWrapperFactory.sol";

import "../../../misc/ScaledTokenMath.sol";

contract PendleUniBTCBaseSYUpgScaled18 is SYBaseUpg, ScaledTokenMath {
    address public constant VAULT = 0x9f283B0401d9698e86097fdC44820BcBE5DcfeFb;
    address public constant UNIBTC = 0x93919784C523f39CACaa98Ee0a9d96c3F32b593e;
    address public constant CBBTC = 0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf;
    address public constant DECIMALS_WRAPPER_FACTORY = 0x992EC6A490A4B7f256bd59E63746951D98B29Be9;

    address public immutable wrappedAsset = IPDecimalsWrapperFactory(DECIMALS_WRAPPER_FACTORY).getOrCreate(UNIBTC, 18);

    constructor()
        SYBaseUpg(UNIBTC)
        ScaledTokenMath(UNIBTC, IPDecimalsWrapperFactory(DECIMALS_WRAPPER_FACTORY).getOrCreate(UNIBTC, 18))
    {
        _disableInitializers();
    }

    function initialize() external initializer {
        _safeApproveInf(CBBTC, VAULT);
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
        return amountDeposited;
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
        return ArrayLib.create(CBBTC, UNIBTC);
    }

    function getTokensOut() public pure override returns (address[] memory res) {
        return ArrayLib.create(UNIBTC);
    }

    function isValidTokenIn(address token) public pure override returns (bool) {
        return token == CBBTC || token == UNIBTC;
    }

    function isValidTokenOut(address token) public pure override returns (bool) {
        return token == UNIBTC;
    }

    function assetInfo() external view returns (AssetType assetType, address assetAddress, uint8 assetDecimals) {
        return (AssetType.TOKEN, wrappedAsset, IERC20Metadata(wrappedAsset).decimals());
    }
}
