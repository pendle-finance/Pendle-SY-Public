// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IPDecimalsWrapper is IERC20Metadata {
    function wrap(uint256 amount) external returns (uint256 amountOut);

    function unwrap(uint256 amount) external returns (uint256 amountOut);

    function rawToken() external view returns (address);

    function rawDecimals() external view returns (uint8);

    function rawToWrapped(uint256 amount) external view returns (uint256);

    function wrappedToRaw(uint256 amount) external view returns (uint256);
}
