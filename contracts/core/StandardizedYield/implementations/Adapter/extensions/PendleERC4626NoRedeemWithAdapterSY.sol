// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../../../SYBaseUpg.sol";
import "../../../../../interfaces/IERC4626.sol";
import "../../../../../interfaces/IStandardizedYieldAdapter.sol";
import "../../../../../interfaces/IPStandardizedYieldWithAdapter.sol";
import "../../../../misc/MerklRewardAbstract__NoStorage.sol";

contract PendleERC4626NoRedeemWithAdapterSY is
    SYBaseUpg,
    MerklRewardAbstract__NoStorage,
    IPStandardizedYieldWithAdapter
{
    using ArrayLib for address[];

    address public immutable asset;
    address public adapter;
    uint256[100] private __gap;

    constructor(
        address _erc4626,
        address _offchainRewardManager
    ) SYBaseUpg(_erc4626) MerklRewardAbstract__NoStorage(_offchainRewardManager) {
        asset = IERC4626(_erc4626).asset();
    }

    function initialize(string memory _name, string memory _symbol, address _adapter) external virtual initializer {
        __SYBaseUpg_init(_name, _symbol);
        _safeApproveInf(asset, yieldToken);
        _setAdapter(_adapter);
    }

    function setAdapter(address _adapter) external virtual override onlyOwner {
        _setAdapter(_adapter);
    }

    function _setAdapter(address _adapter) internal {
        require(
            _adapter == address(0) || IStandardizedYieldAdapter(_adapter).PIVOT_TOKEN() == asset,
            "_setAdapter: invalid adapter"
        );
        adapter = _adapter;
        emit SetAdapter(_adapter);
    }

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 amountSharesOut) {
        if (tokenIn != yieldToken && tokenIn != asset) {
            _transferOut(tokenIn, adapter, amountDeposited);
            (tokenIn, amountDeposited) = (
                asset,
                IStandardizedYieldAdapter(adapter).convertToDeposit(tokenIn, amountDeposited)
            );
        }

        if (tokenIn == yieldToken) {
            amountSharesOut = amountDeposited;
        } else {
            amountSharesOut = IERC4626(yieldToken).deposit(amountDeposited, address(this));
        }

        require(_selfBalance(yieldToken) >= totalSupply() + amountSharesOut, "SY: insufficient shares");
    }

    function _redeem(
        address receiver,
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal virtual override returns (uint256) {
        _transferOut(yieldToken, receiver, amountSharesToRedeem);
        return amountSharesToRedeem;
    }

    function exchangeRate() public view virtual override returns (uint256) {
        return IERC4626(yieldToken).convertToAssets(PMath.ONE);
    }

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn != yieldToken && tokenIn != asset) {
            (tokenIn, amountTokenToDeposit) = (
                asset,
                IStandardizedYieldAdapter(adapter).previewConvertToDeposit(tokenIn, amountTokenToDeposit)
            );
        }

        if (tokenIn == yieldToken) {
            return amountTokenToDeposit;
        } else {
            return IERC4626(yieldToken).previewDeposit(amountTokenToDeposit);
        }
    }

    function _previewRedeem(
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal view virtual override returns (uint256 /*amountTokenOut*/) {
        return amountSharesToRedeem;
    }

    function getTokensIn() public view virtual override returns (address[] memory res) {
        if (adapter == address(0)) {
            return ArrayLib.create(asset, yieldToken);
        }
        return IStandardizedYieldAdapter(adapter).getAdapterTokensDeposit().append(asset, yieldToken);
    }

    function getTokensOut() public view virtual override returns (address[] memory res) {
        return ArrayLib.create(yieldToken);
    }

    function isValidTokenIn(address token) public view virtual override returns (bool) {
        if (adapter == address(0)) {
            return token == yieldToken || token == asset;
        }

        return
            token == yieldToken ||
            token == asset ||
            IStandardizedYieldAdapter(adapter).getAdapterTokensDeposit().contains(token);
    }

    function isValidTokenOut(address token) public view virtual override returns (bool) {
        return token == yieldToken;
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
