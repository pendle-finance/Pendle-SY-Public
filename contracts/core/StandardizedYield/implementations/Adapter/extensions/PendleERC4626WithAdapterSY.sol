// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../../../SYBaseUpg.sol";
import "../../../../../interfaces/IERC4626.sol";
import "../../../../../interfaces/IStandardizedYieldAdapter.sol";

contract PendleERC4626WithAdapterSY is SYBaseUpg {
    using PMath for uint256;
    using ArrayLib for address[];

    address public immutable asset;
    address public immutable adapter;

    constructor(address _erc4626, address _adapter) SYBaseUpg(_erc4626) {
        asset = IERC4626(_erc4626).asset();
        adapter = _adapter;

        assert(adapter != address(0));
    }

    function initialize(string memory _name, string memory _symbol) external virtual initializer {
        __SYBaseUpg_init(_name, _symbol);
        _safeApproveInf(asset, yieldToken);
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
        if (tokenIn != yieldToken && tokenIn != asset) {
            (tokenIn, amountDeposited) = IStandardizedYieldAdapter(adapter).convertToDeposit(tokenIn, amountDeposited);
        }

        if (tokenIn == yieldToken) {
            return amountDeposited;
        } else {
            return IERC4626(yieldToken).deposit(amountDeposited, address(this));
        }
    }

    function _redeem(
        address receiver,
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal virtual override returns (uint256 amountTokenOut) {
        if (tokenOut == yieldToken) {
            amountTokenOut = amountSharesToRedeem;
            _transferOut(yieldToken, receiver, amountTokenOut);
        } else if (tokenOut == asset) {
            amountTokenOut = IERC4626(yieldToken).redeem(amountSharesToRedeem, receiver, address(this));
        } else {
            amountTokenOut = IStandardizedYieldAdapter(adapter).convertToRedeem(tokenOut, amountSharesToRedeem);
            _transferOut(tokenOut, receiver, amountTokenOut);
        }
    }

    function exchangeRate() public view virtual override returns (uint256) {
        return IERC4626(yieldToken).convertToAssets(PMath.ONE);
    }

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn != yieldToken && tokenIn != asset) {
            (tokenIn, amountTokenToDeposit) = IStandardizedYieldAdapter(adapter).previewConvertToDeposit(
                tokenIn,
                amountTokenToDeposit
            );
        }

        if (tokenIn == yieldToken) {
            return amountTokenToDeposit;
        } else {
            return IERC4626(yieldToken).previewDeposit(amountTokenToDeposit);
        }
    }

    function _previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal view virtual override returns (uint256 /*amountTokenOut*/) {
        if (tokenOut == yieldToken) {
            return amountSharesToRedeem;
        } else if (tokenOut == asset) {
            return IERC4626(yieldToken).previewRedeem(amountSharesToRedeem);
        } else {
            return IStandardizedYieldAdapter(adapter).previewConvertToRedeem(tokenOut, amountSharesToRedeem);
        }
    }

    function getTokensIn() public view virtual override returns (address[] memory res) {
        return IStandardizedYieldAdapter(adapter).getAdapterTokensDeposit().append(asset, yieldToken);
    }

    function getTokensOut() public view virtual override returns (address[] memory res) {
        return IStandardizedYieldAdapter(adapter).getAdapterTokensRedeem().append(asset, yieldToken);
    }

    function isValidTokenIn(address token) public view virtual override returns (bool) {
        return
            token == yieldToken ||
            token == asset ||
            IStandardizedYieldAdapter(adapter).getAdapterTokensDeposit().contains(token);
    }

    function isValidTokenOut(address token) public view virtual override returns (bool) {
        return
            token == yieldToken ||
            token == asset ||
            IStandardizedYieldAdapter(adapter).getAdapterTokensRedeem().contains(token);
    }

    function assetInfo()
        external
        view
        virtual
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.TOKEN, asset, IERC20Metadata(asset).decimals());
    }
}
