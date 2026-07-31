// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../../../../interfaces/IPTokenWithSupplyCap.sol";
import "../../../../interfaces/Upshift/ITokenizedVault.sol";

interface IPUpshiftTokenizedVaultSY {
    function tokenizedVault() external view returns (address);

    function yieldToken() external view returns (address);
}

contract PendleUpshiftExternalCap is IPTokenWithSupplyCap {
    address public immutable sy;
    address public immutable tokenizedVault;
    address public immutable yieldToken;
    uint256 public immutable oneShare;

    constructor(address _sy) {
        sy = _sy;
        tokenizedVault = IPUpshiftTokenizedVaultSY(_sy).tokenizedVault();
        yieldToken = IPUpshiftTokenizedVaultSY(_sy).yieldToken();
        oneShare = 10 ** IERC20Metadata(yieldToken).decimals();
    }

    function getAbsoluteSupplyCap() external view returns (uint256) {
        uint256 depositCap = ITokenizedVault(tokenizedVault).depositCap();
        if (depositCap == type(uint256).max) return type(uint256).max;

        uint256 totalAssets = ITokenizedVault(tokenizedVault).getTotalAssets();
        if (totalAssets >= depositCap) return _getAbsoluteTotalSupply();

        uint256 sharePrice = ITokenizedVault(tokenizedVault).getSharePrice();
        uint256 mintableShares = ((depositCap - totalAssets) * oneShare) / sharePrice;
        return _getAbsoluteTotalSupply() + mintableShares;
    }

    function getAbsoluteTotalSupply() external view returns (uint256) {
        return _getAbsoluteTotalSupply();
    }

    function _getAbsoluteTotalSupply() internal view returns (uint256) {
        return IERC20(yieldToken).totalSupply();
    }
}
