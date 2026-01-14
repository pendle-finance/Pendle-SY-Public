// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface InfiniFiGateway {
    function mint(address _to, uint256 _amount) external returns (uint256);
    function redeem(address _to, uint256 _amount, uint256 _minAmountOut) external returns (uint256);
    function getAddress(string memory _name) external view returns (address);
}

interface IMintController {
    function assetToReceipt(uint256 _assetAmount) external view returns (uint256);
}

interface IRedeemController {
    function receiptToAsset(uint256 _receiptAmount) external view returns (uint256);
}
