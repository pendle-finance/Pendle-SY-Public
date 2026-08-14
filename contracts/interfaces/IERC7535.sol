// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IERC7535 is IERC20Metadata {
    function asset() external view returns (address);

    function deposit(uint256 assets, address receiver) external payable returns (uint256);

    function redeem(uint256 shares, address receiver, address owner) external returns (uint256);

    function convertToAssets(uint256 shares) external view returns (uint256);

    function convertToShares(uint256 assets) external view returns (uint256);

    function previewDeposit(uint256 assets) external view returns (uint256);

    function previewRedeem(uint256 shares) external view returns (uint256);
}
