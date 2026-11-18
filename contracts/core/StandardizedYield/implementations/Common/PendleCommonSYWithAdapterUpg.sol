// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.28;

import "../../v3/SYBaseUpgV3.sol";
import "../../../../interfaces/IStandardizedYieldAdapter.sol";
import "../../../../interfaces/IPStandardizedYieldWithAdapter.sol";
import "../../../misc/MerklRewardAbstract__NoStorage.sol";

/// @dev Adapter plumbing shared by the Common SYs. The adapter converts its own tokens to and from `pivotToken`.
abstract contract PendleCommonSYWithAdapterUpg is
    SYBaseUpgV3,
    MerklRewardAbstract__NoStorage,
    IPStandardizedYieldWithAdapter
{
    using ArrayLib for address[];

    address internal immutable pivotToken;

    address public adapter;

    uint256[100] private __gap;

    constructor(
        address _yieldToken,
        address _pivotToken,
        address _offchainRewardManager
    ) SYBaseUpgV3(_yieldToken) MerklRewardAbstract__NoStorage(_offchainRewardManager) {
        pivotToken = _pivotToken;
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        address _adapter,
        address _owner
    ) external initializer {
        __SYBaseUpgV3_init(_name, _symbol, _owner);
        _afterInitialize();
        _setAdapter(_adapter);
    }

    function _afterInitialize() internal virtual {}

    function setAdapter(address _adapter) external override onlyOwner {
        _setAdapter(_adapter);
    }

    function _setAdapter(address _adapter) internal {
        require(
            _adapter == address(0) || IStandardizedYieldAdapter(_adapter).PIVOT_TOKEN() == pivotToken,
            "SY: invalid adapter"
        );
        adapter = _adapter;
        emit SetAdapter(_adapter);
    }

    /// @dev sends `amountIn` of `tokenIn` to the adapter and returns the amount of `pivotToken` received
    function _adapterDeposit(address tokenIn, uint256 amountIn) internal returns (uint256) {
        address _adapter = adapter;
        _transferOut(tokenIn, _adapter, amountIn);
        return IStandardizedYieldAdapter(_adapter).convertToDeposit(tokenIn, amountIn);
    }

    function _isAdapterTokenIn(address token) internal view returns (bool) {
        return adapter != address(0) && IStandardizedYieldAdapter(adapter).getAdapterTokensDeposit().contains(token);
    }

    function _isAdapterTokenOut(address token) internal view returns (bool) {
        return adapter != address(0) && IStandardizedYieldAdapter(adapter).getAdapterTokensRedeem().contains(token);
    }
}
