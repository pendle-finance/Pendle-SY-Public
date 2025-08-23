// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface ICUSD {
    function mint(address _asset, uint256 _amountIn, uint256 _minAmountOut, address _receiver, uint256 _deadline)
        external
        returns (uint256 amountOut);

    function burn(address _asset, uint256 _amountIn, uint256 _minAmountOut, address _receiver, uint256 _deadline)
        external
        returns (uint256 amountOut);

    function assets() external view returns (address[] memory assetList);
    function paused(address _asset) external view returns (bool isPaused);

    function getMintAmount(address _asset, uint256 _amountIn) external view returns (uint256 amountOut, uint256 fee);
    function getBurnAmount(address _asset, uint256 _amountIn) external view returns (uint256 amountOut, uint256 fee);
}
