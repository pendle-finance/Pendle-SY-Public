// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEnableOnlyAssetsWhitelist {
    function getWhitelistedAssets() external view returns (address[] memory);

    function isWhitelisted(address addr) external view returns (bool);
}
