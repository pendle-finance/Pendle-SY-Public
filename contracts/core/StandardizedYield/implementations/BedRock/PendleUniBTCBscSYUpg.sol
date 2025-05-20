// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../../SYBaseUpg.sol";
import "../../../../interfaces/Bedrock/IBedrockUniBTCVault.sol";

contract PendleUniBTCBscSYUpg is SYBaseUpg {
    address public constant VAULT = 0x84E5C854A7fF9F49c888d69DECa578D406C26800;
    address public constant UNIBTC = 0x6B2a01A5f79dEb4c2f3c0eDa7b01DF456FbD726a;
    address public constant WBTC = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;

    uint256 public constant EXCHANGE_RATE_BASE = 1e10;

    constructor() SYBaseUpg(UNIBTC) {
        _disableInitializers();
    }

    function initialize() external initializer {
        _safeApproveInf(WBTC, VAULT);
        __SYBaseUpg_init("SY Bedrock uniBTC", "SY-uniBTC");
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
        return PMath.ONE;
    }

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == WBTC) {
            return amountTokenToDeposit / EXCHANGE_RATE_BASE;
        }
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
        return (AssetType.TOKEN, UNIBTC, IERC20Metadata(UNIBTC).decimals());
    }
}
