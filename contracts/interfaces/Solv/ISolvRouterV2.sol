// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISolvRouterV2 {
    function deposit(
        address targetToken_,
        address currency_,
        uint256 currencyAmount_,
        uint256 minimumTargetTokenAmount_, 
        uint64 expireTime_
    ) external returns (uint256 targetTokenAmount_);

    function poolIds(address targetToken_, address currency_) external view returns (bytes32);

    function openFundMarket() external view returns (address);
}
