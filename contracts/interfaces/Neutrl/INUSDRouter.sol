// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INUSDRouter {
    function mint(
        address _beneficiary,
        address _collateralAsset,
        uint256 _collateralAmount,
        uint256 _minNusdAmount,
        bytes calldata _additionalData
    ) external;

    function quoteDeposit(address _collateralAsset, uint256 _amount) external view returns (uint256);
}
