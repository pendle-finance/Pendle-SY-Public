// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../../../SYBaseUpg.sol";
import "../../../../../interfaces/IStandardizedYieldAdapter.sol";

contract PendleERC20WithAdapterSY is SYBaseUpg {
    using PMath for uint256;
    using ArrayLib for address[];

    // solhint-disable immutable-vars-naming
    address public immutable adapter;

    constructor(address _erc20, address _adapter) SYBaseUpg(_erc20) {
        adapter = _adapter;
        assert(adapter != address(0));
    }

    function initialize(string memory _name, string memory _symbol) external virtual initializer {
        __SYBaseUpg_init(_name, _symbol);
        approveForAdapter();
    }

    function approveForAdapter() public {
        _safeApproveInf(yieldToken, adapter);
        address[] memory tokensIn = IStandardizedYieldAdapter(adapter).getAdapterTokensDeposit();
        for (uint256 i = 0; i < tokensIn.length; i++) {
            _safeApproveInf(tokensIn[i], adapter);
        }
    }

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == yieldToken) {
            return amountDeposited;
        } else {
            (, uint256 amountOut) = IStandardizedYieldAdapter(adapter).convertToDeposit(tokenIn, amountDeposited);
            return amountOut;
        }
    }

    function _redeem(
        address receiver,
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal override returns (uint256) {
        if (tokenOut == yieldToken) {
            _transferOut(yieldToken, receiver, amountSharesToRedeem);
            return amountSharesToRedeem;
        } else {
            uint256 amountOut = IStandardizedYieldAdapter(adapter).convertToRedeem(tokenOut, amountSharesToRedeem);
            _transferOut(tokenOut, receiver, amountOut);
            return amountOut;
        }
    }

    function exchangeRate() public view virtual override returns (uint256 res) {
        return PMath.ONE;
    }

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == yieldToken) {
            return amountTokenToDeposit;
        } else {
            (, uint256 amountOut) = IStandardizedYieldAdapter(adapter).previewConvertToDeposit(
                tokenIn,
                amountTokenToDeposit
            );
            return amountOut;
        }
    }

    function _previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal view virtual override returns (uint256 /*amountTokenOut*/) {
        if (tokenOut == yieldToken) {
            return amountSharesToRedeem;
        } else {
            uint256 amountOut = IStandardizedYieldAdapter(adapter).previewConvertToRedeem(
                tokenOut,
                amountSharesToRedeem
            );
            return amountOut;
        }
    }

    function getTokensIn() public view virtual override returns (address[] memory res) {
        return IStandardizedYieldAdapter(adapter).getAdapterTokensDeposit().append(yieldToken);
    }

    function getTokensOut() public view override returns (address[] memory res) {
        return IStandardizedYieldAdapter(adapter).getAdapterTokensRedeem().append(yieldToken);
    }

    function isValidTokenIn(address token) public view virtual override returns (bool) {
        return token == yieldToken || IStandardizedYieldAdapter(adapter).getAdapterTokensDeposit().contains(token);
    }

    function isValidTokenOut(address token) public view override returns (bool) {
        return token == yieldToken || IStandardizedYieldAdapter(adapter).getAdapterTokensRedeem().contains(token);
    }

    function assetInfo()
        external
        view
        virtual
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.TOKEN, yieldToken, IERC20Metadata(yieldToken).decimals());
    }

    uint256[100] private __gap;
}
