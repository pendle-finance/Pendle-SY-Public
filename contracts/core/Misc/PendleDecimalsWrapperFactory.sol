// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./PendleDecimalsWrapper.sol";
import "../libraries/StringLib.sol";
import "../../interfaces/IPDecimalsWrapperFactory.sol";

contract PendleDecimalsWrapperFactory is IPDecimalsWrapperFactory {
    mapping(address => mapping(uint8 => address)) public decimalWrappers;

    function createOrGet(address _rawToken, uint8 _decimals) external returns (address decimalWrapper) {
        decimalWrapper = decimalWrappers[_rawToken][_decimals];
        if (decimalWrapper == address(0)) {
            decimalWrapper = _createDecimalWrapper(_rawToken, _decimals);
        }
    }

    function _createDecimalWrapper(address _rawToken, uint8 _decimals) internal returns (address decimalWrapper) {
        string memory name = string(abi.encodePacked(IERC20Metadata(_rawToken).name(), "-scaled18"));
        string memory symbol = string(abi.encodePacked(IERC20Metadata(_rawToken).symbol(), "-scaled18"));
        decimalWrapper = address(new PendleDecimalsWrapper(name, symbol, _rawToken));
        decimalWrappers[_rawToken][_decimals] = decimalWrapper;

        emit DecimalWrapperCreated(_rawToken, _decimals, decimalWrapper);
    }
}
