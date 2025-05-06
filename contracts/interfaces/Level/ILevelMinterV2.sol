// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ILevelMinterV2 {
    struct Order {
        address beneficiary;
        address collateral_asset;
        uint256 collateral_amount;
        uint256 min_lvlusd_amount;
    }

    function mint(Order calldata order) external returns (uint256);

    function oracles(address token) external view returns (address);

    function vaultManager() external view returns (address);
}
