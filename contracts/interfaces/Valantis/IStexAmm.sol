// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStexAmm {
    function deposit(
        uint256 _amount,
        uint256 _minShares,
        uint256 _deadline,
        address _recipient
    ) external returns (uint256 shares);

    function withdraw(
        uint256 _shares,
        uint256 _amount0Min,
        uint256 _amount1Min,
        uint256 _deadline,
        address _recipient,
        bool _unwrapToNativeToken,
        bool _isInstantWithdrawal
    ) external returns (uint256 amount0, uint256 amount1);

    function pool() external view returns (address);

    function token1() external view returns (address);

    function totalSupply() external view returns (uint256);
}
