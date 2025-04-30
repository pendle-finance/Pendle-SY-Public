// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../../../SYBaseUpg.sol";
import "../../../../../interfaces/IStandardizedYieldAdapter.sol";
import "../../../../../interfaces/IPStandardizedYieldWithAdapter.sol";

contract PendleERC20WithAdapterSY is SYBaseUpg, IPStandardizedYieldWithAdapter {
    using ArrayLib for address[];

    // solhint-disable immutable-vars-naming
    address public adapter;

    constructor(address _erc20) SYBaseUpg(_erc20) {}

    function initialize(string memory _name, string memory _symbol, address _adapter) external virtual initializer {
        __SYBaseUpg_init(_name, _symbol);
        _setAdapter(_adapter);
    }

    function setAdapter(address _adapter) external virtual override onlyOwner {
        _setAdapter(_adapter);
    }

    function _setAdapter(address _adapter) internal {
        require(_adapter != address(0), "_setAdapter: zero address");
        require(IStandardizedYieldAdapter(_adapter).PIVOT_TOKEN() == yieldToken, "_setAdapter: invalid adapter");
        adapter = _adapter;
        emit SetAdapter(_adapter);
    }

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 amountSharesOut) {
        if (tokenIn == yieldToken) {
            amountSharesOut = amountDeposited;
        } else {
            _transferOut(tokenIn, adapter, amountDeposited);
            amountSharesOut = IStandardizedYieldAdapter(adapter).convertToDeposit(tokenIn, amountDeposited);
        }

        require(_selfBalance(yieldToken) >= totalSupply() + amountSharesOut, "SY: insufficient shares");
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
            _transferOut(yieldToken, adapter, amountSharesToRedeem);
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
            return IStandardizedYieldAdapter(adapter).previewConvertToDeposit(tokenIn, amountTokenToDeposit);
        }
    }

    function _previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal view virtual override returns (uint256 /*amountTokenOut*/) {
        if (tokenOut == yieldToken) {
            return amountSharesToRedeem;
        } else {
            return IStandardizedYieldAdapter(adapter).previewConvertToRedeem(tokenOut, amountSharesToRedeem);
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
