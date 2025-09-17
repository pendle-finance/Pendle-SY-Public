// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.29;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../../../interfaces/IStandardizedYieldAdapter.sol";
import "../../../../interfaces/USDai/IUSDai.sol";

/**
 * @title Pendle USDai Adapter
 * @author MetaStreet Foundation
 */
contract PendleUSDaiAdapter is IStandardizedYieldAdapter {
    using SafeERC20 for IERC20;

    /*------------------------------------------------------------------------*/
    /* Constants */
    /*------------------------------------------------------------------------*/

    /**
     * @notice USDai
     */
    IUSDai internal constant USDAI = IUSDai(0x0A1a1A107E45b7Ced86833863f482BC5f4ed82EF);

    /*------------------------------------------------------------------------*/
    /* Immutable state */
    /*------------------------------------------------------------------------*/

    /**
     * @notice Base token
     */
    address internal immutable _baseToken;

    /**
     * @notice Scale factor
     */
    uint256 internal immutable _scaleFactor;

    /*------------------------------------------------------------------------*/
    /* Errors */
    /*------------------------------------------------------------------------*/

    /**
     * @notice Unsupported token
     * @param token Token address
     */
    error UnsupportedToken(address token);

    /*------------------------------------------------------------------------*/
    /* Constructor */
    /*------------------------------------------------------------------------*/

    /**
     * @notice PendleUSDaiAdapterSY constructor
     */
    constructor() {
        _baseToken = USDAI.baseToken();
        _scaleFactor = 10 ** (18 - IERC20Metadata(_baseToken).decimals());

        /* Approve the adapter to spend the base token */
        IERC20(address(_baseToken)).forceApprove(address(USDAI), type(uint256).max);
    }

    /*------------------------------------------------------------------------*/
    /* Internal helpers */
    /*------------------------------------------------------------------------*/

    /**
     * @notice Helper function to scale up a value
     * @param value Value
     * @return Scaled value
     */
    function _scale(uint256 value) internal view returns (uint256) {
        return value * _scaleFactor;
    }

    /**
     * @notice Helper function to scale down a value
     * @param value Value
     * @return Unscaled value
     */
    function _unscale(uint256 value) internal view returns (uint256) {
        return value / _scaleFactor;
    }

    /*------------------------------------------------------------------------*/
    /* IStandardizedYieldAdapter */
    /*------------------------------------------------------------------------*/

    /**
     * @inheritdoc IStandardizedYieldAdapter
     */
    function PIVOT_TOKEN() external pure returns (address) {
        return address(USDAI);
    }

    /**
     * @inheritdoc IStandardizedYieldAdapter
     */
    function convertToDeposit(address tokenIn, uint256 amountTokenIn) external returns (uint256) {
        /* Validate token in is base token */
        if (tokenIn != _baseToken) revert UnsupportedToken(tokenIn);

        /* Deposit the token in */
        return USDAI.deposit(_baseToken, amountTokenIn, 0, msg.sender, "");
    }

    /**
     * @inheritdoc IStandardizedYieldAdapter
     */
    function convertToRedeem(address tokenOut, uint256 amountYieldTokenIn) external returns (uint256 amountOut) {
        /* Validate token out is base token */
        if (tokenOut != _baseToken) revert UnsupportedToken(tokenOut);

        /* Withdraw the USDai */
        return USDAI.withdraw(tokenOut, amountYieldTokenIn, 0, msg.sender, "");
    }

    /**
     * @inheritdoc IStandardizedYieldAdapter
     */
    function previewConvertToDeposit(address tokenIn, uint256 amountTokenIn)
        external
        view
        returns (uint256 amountOut)
    {
        /* Validate token in is base token */
        if (tokenIn != _baseToken) revert UnsupportedToken(tokenIn);

        /* Get deposit quote */
        return _scale(amountTokenIn);
    }

    /**
     * @inheritdoc IStandardizedYieldAdapter
     */
    function previewConvertToRedeem(address tokenOut, uint256 amountYieldTokenIn)
        external
        view
        returns (uint256 amountOut)
    {
        /* Validate token out is base token */
        if (tokenOut != _baseToken) revert UnsupportedToken(tokenOut);

        /* Get withdraw quote */
        return _unscale(amountYieldTokenIn);
    }

    /**
     * @inheritdoc IStandardizedYieldAdapter
     */
    function getAdapterTokensDeposit() external view returns (address[] memory tokens) {
        tokens = new address[](1);
        tokens[0] = _baseToken;
    }

    /**
     * @inheritdoc IStandardizedYieldAdapter
     */
    function getAdapterTokensRedeem() external view returns (address[] memory tokens) {
        tokens = new address[](1);
        tokens[0] = _baseToken;
    }
}
