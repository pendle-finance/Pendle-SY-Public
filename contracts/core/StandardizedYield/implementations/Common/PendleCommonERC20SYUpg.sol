// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.28;

import "./PendleCommonSYWithAdapterUpg.sol";
import "../../../libraries/DecimalsWrapperLib.sol";

contract PendleCommonERC20SYUpg is PendleCommonSYWithAdapterUpg {
    using ArrayLib for address[];

    address public immutable erc20;
    uint256 internal immutable scale;

    uint256[100] private __gap;

    constructor(
        address _erc20,
        address _decimalsWrapperFactory,
        address _offchainRewardManager
    )
        PendleCommonSYWithAdapterUpg(
            DecimalsWrapperLib.scaled18(_decimalsWrapperFactory, _erc20),
            _erc20,
            _offchainRewardManager
        )
    {
        erc20 = _erc20;
        scale = DecimalsWrapperLib.scale18(_erc20);
    }

    /*///////////////////////////////////////////////////////////////
                    DEPOSIT/REDEEM USING BASE TOKENS
    //////////////////////////////////////////////////////////////*/

    function _deposit(address tokenIn, uint256 amountIn) internal override returns (uint256 amountSharesOut) {
        if (tokenIn != erc20) amountIn = _adapterDeposit(tokenIn, amountIn);
        amountSharesOut = amountIn * scale;
        require(_selfBalance(erc20) * scale >= totalSupply() + amountSharesOut, "SY: insufficient shares");
    }

    function _redeem(
        address receiver,
        address tokenOut,
        uint256 amountShares
    ) internal override returns (uint256 amountOut) {
        amountOut = amountShares / scale;
        if (tokenOut != erc20) {
            address _adapter = adapter;
            _transferOut(erc20, _adapter, amountOut);
            amountOut = IStandardizedYieldAdapter(_adapter).convertToRedeem(tokenOut, amountOut);
        }
        _transferOut(tokenOut, receiver, amountOut);
    }

    function _previewDeposit(address tokenIn, uint256 amountIn) internal view override returns (uint256) {
        if (tokenIn != erc20) amountIn = IStandardizedYieldAdapter(adapter).previewConvertToDeposit(tokenIn, amountIn);
        return amountIn * scale;
    }

    function _previewRedeem(address tokenOut, uint256 amountShares) internal view override returns (uint256 amountOut) {
        amountOut = amountShares / scale;
        if (tokenOut != erc20)
            amountOut = IStandardizedYieldAdapter(adapter).previewConvertToRedeem(tokenOut, amountOut);
    }

    /*///////////////////////////////////////////////////////////////
                               EXCHANGE-RATE
    //////////////////////////////////////////////////////////////*/

    function exchangeRate() public view virtual override returns (uint256) {
        return PMath.ONE;
    }

    /*///////////////////////////////////////////////////////////////
                        MISC FUNCTIONS FOR METADATA
    //////////////////////////////////////////////////////////////*/

    function getTokensIn() public view override returns (address[] memory) {
        if (adapter == address(0)) return ArrayLib.create(erc20);
        return IStandardizedYieldAdapter(adapter).getAdapterTokensDeposit().append(erc20);
    }

    function getTokensOut() public view override returns (address[] memory) {
        if (adapter == address(0)) return ArrayLib.create(erc20);
        return IStandardizedYieldAdapter(adapter).getAdapterTokensRedeem().append(erc20);
    }

    function isValidTokenIn(address token) public view override returns (bool) {
        return token == erc20 || _isAdapterTokenIn(token);
    }

    function isValidTokenOut(address token) public view override returns (bool) {
        return token == erc20 || _isAdapterTokenOut(token);
    }

    function assetInfo() external view virtual returns (AssetType, address, uint8) {
        return (AssetType.TOKEN, yieldToken, 18);
    }

    function pricingInfo() external view override returns (address refToken, bool refStrictlyEqual) {
        return (erc20, true);
    }
}
