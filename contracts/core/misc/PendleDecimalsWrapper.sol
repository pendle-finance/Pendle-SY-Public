// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../erc20/PendleERC20.sol";
import "../../interfaces/IPDecimalsWrapper.sol";
import "../../interfaces/IPDecimalsWrapperFactory.sol";
import "../libraries/TokenHelper.sol";

contract PendleDecimalsWrapper is PendleERC20, TokenHelper, IPDecimalsWrapper {
    address public immutable factory;
    address public immutable rawToken;
    uint8 public immutable rawDecimals;

    constructor(string memory name_, string memory symbol_, address rawToken_) PendleERC20(name_, symbol_, 18) {
        rawToken = rawToken_;
        factory = msg.sender;
        rawDecimals = IERC20Metadata(rawToken).decimals();
        assert(rawDecimals <= 18);
    }

    function wrap(uint256 amount) external returns (uint256 amountOut) {
        _transferIn(rawToken, msg.sender, amount);
        amountOut = rawToWrapped(amount);
        _mint(msg.sender, amountOut);
    }

    function unwrap(uint256 amount) external returns (uint256 amountOut) {
        _burn(msg.sender, amount);
        amountOut = wrappedToRaw(amount);
        _transferOut(rawToken, msg.sender, amountOut);
    }

    function rawToWrapped(uint256 amount) public view returns (uint256) {
        return amount * (10 ** (18 - rawDecimals));
    }

    function wrappedToRaw(uint256 amount) public view returns (uint256) {
        return amount / (10 ** (18 - rawDecimals));
    }

    function sweep() external {
        uint256 balance = _selfBalance(rawToken) - wrappedToRaw(totalSupply());
        if (balance > 0) {
            _transferOut(rawToken, IPDecimalsWrapperFactory(factory).dustReceiver(), balance);
        }
    }
}
