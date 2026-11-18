// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../../interfaces/IPRateLimiter.sol";

abstract contract TokenWithRateLimit {
    address public constant RATE_LIMITER = 0x94604284c47e0308526687798185346f8Ea0440C;

    function _rateLimitMint(uint256 amount) internal {
        IPRateLimiter(RATE_LIMITER).onMint(msg.sender, amount);
    }

    function _rateLimitBurn(uint256 amount) internal {
        IPRateLimiter(RATE_LIMITER).onBurn(msg.sender, amount);
    }
}
