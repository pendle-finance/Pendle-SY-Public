// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

pragma solidity ^0.8.0;

import "./IStandardizedYield.sol";

interface IStandardizedYieldExtended is IStandardizedYield {
    
    /**
     * @notice This function contains information to describe recommended pricing method for this SY
     * @return refToken the token should be referred to when pricing this SY
     * @return refWithoutExRate whether the price of refToken should be multiplied with SY.exchangeRate() to obtain SY price
     *
     * @dev For pricing PT & YT of this SY, it's recommended that:
     * - refWithoutExRate = true : use PYLpOracle.get{Token}ToSyRate() and multiply with refToken's according price
     * - refWithoutExRate = false: use PYLpOracle.get{Token}ToAssetRate() and multiply with refToken's according price
     */
    function pricingInfo() external view returns (address refToken, bool refWithoutExRate);
}