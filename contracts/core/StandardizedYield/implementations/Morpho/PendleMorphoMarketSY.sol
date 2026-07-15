// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../../v2/SYBaseUpgV2.sol";
import "../../../../interfaces/Morpho/IPMorphoMarketWrapper.sol";

contract PendleMorphoMarketSY is SYBaseUpgV2 {
    address public immutable loanToken;

    constructor(address _morphoMarketWrapper) SYBaseUpgV2(_morphoMarketWrapper) {
        loanToken = IPMorphoMarketWrapper(_morphoMarketWrapper).loanToken();
    }

    function initialize(string memory _name, string memory _symbol, address _owner) external initializer {
        __SYBaseUpgV2_init(_name, _symbol, _owner);
        _safeApproveInf(loanToken, yieldToken);
    }

    function _deposit(
        address /*tokenIn*/,
        uint256 amountDeposited
    ) internal override returns (uint256 amountSharesOut) {
        return IPMorphoMarketWrapper(yieldToken).deposit(amountDeposited);
    }

    function _redeem(
        address receiver,
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal override returns (uint256 amountTokenOut) {
        return IPMorphoMarketWrapper(yieldToken).redeem(amountSharesToRedeem, receiver);
    }

    function exchangeRate() public view override returns (uint256) {
        return IPMorphoMarketWrapper(yieldToken).exchangeRate();
    }

    function _previewDeposit(
        address /*tokenIn*/,
        uint256 amountTokenToDeposit
    ) internal view override returns (uint256) {
        return IPMorphoMarketWrapper(yieldToken).previewDeposit(amountTokenToDeposit);
    }

    function _previewRedeem(
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal view override returns (uint256) {
        return IPMorphoMarketWrapper(yieldToken).previewRedeem(amountSharesToRedeem);
    }

    function getTokensIn() public view override returns (address[] memory res) {
        return ArrayLib.create(loanToken);
    }

    function getTokensOut() public view override returns (address[] memory res) {
        return ArrayLib.create(loanToken);
    }

    function isValidTokenIn(address token) public view override returns (bool) {
        return token == loanToken;
    }

    function isValidTokenOut(address token) public view override returns (bool) {
        return token == loanToken;
    }

    function assetInfo() external view override returns (AssetType, address, uint8) {
        return (AssetType.TOKEN, loanToken, IERC20Metadata(loanToken).decimals());
    }
}
