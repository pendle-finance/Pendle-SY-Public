// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IPDecimalsWrapperFactory {
    event DecimalWrapperCreated(address indexed rawToken, uint8 indexed decimals, address indexed decimalsWrapper);

    function getOrCreate(address _rawToken, uint8 _decimals) external returns (address decimalsWrapper);

    function dustReceiver() external view returns (address);
}
