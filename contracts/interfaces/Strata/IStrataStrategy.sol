// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

interface IStrataStrategy {
    function convertToTokens(
        address token,
        uint256 baseAssets,
        Math.Rounding rounding
    ) external view returns (uint256 tokenAmount);
}
