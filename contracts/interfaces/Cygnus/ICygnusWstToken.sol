// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICygnusWstToken {
    function wrap(uint256 _amount) external returns (uint256);

    function unwrap(uint256 _amount) external returns (uint256);
}
