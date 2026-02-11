// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IHyperbeatPricer {
    function vaultToken() external view returns (address);
    function baseAsset() external view returns (address);
    function getVaultTokenAmount(address _token, uint256 _amount) external view returns (uint256);
    function getAssetAmount(address _token, uint256 _vaultTokenAmount) external view returns (uint256);
}
