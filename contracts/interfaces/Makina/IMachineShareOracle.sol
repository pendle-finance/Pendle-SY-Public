// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IMachineShareOracle {
    /// @notice Decimals of the oracle.
    function decimals() external view returns (uint8);

    /// @notice Returns the price of one machine share token expressed in machine accounting tokens
    /// @dev The price is expressed with `decimals` precision.
    /// @return sharePrice The price of one machine share token expressed in machine accounting tokens, scaled to `decimals` precision.
    function getSharePrice() external view returns (uint256 sharePrice);
}
