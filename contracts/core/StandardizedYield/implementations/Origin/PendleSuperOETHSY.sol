// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../PendleERC4626UpgSYV2.sol";
import "../../../../interfaces/Origin/IOETHVault.sol";

contract PendleSuperOETHSY is PendleERC4626SYUpg {
    address public constant WSOETH = 0x7FcD174E80f264448ebeE8c88a7C4476AAF58Ea6;
    address public constant WETH = 0x4200000000000000000000000000000000000006;
    address public constant OETH_VAULT = 0x98a0CbeF61bD2D21435f433bE4CD42B56B38CC93;

    constructor() PendleERC4626SYUpg(WSOETH) {
        assert(block.chainid == 8453);
    }

    function initialize() external initializer {
        __SYBaseUpg_init("SY Wrapped Super OETHb", "SY-wsuperOETHb");
        _safeApproveInf(asset, yieldToken);
        _safeApproveInf(WETH, OETH_VAULT);
    }

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == yieldToken) {
            return amountDeposited;
        } else {
            if (tokenIn == WETH) {
                IOETHVault(OETH_VAULT).mint(WETH, amountDeposited, 0);
            }
            return IERC4626(yieldToken).deposit(amountDeposited, address(this));
        }
    }

    function getTokensIn() public view override returns (address[] memory res) {
        res = new address[](3);
        res[0] = WETH;
        res[1] = asset;
        res[2] = yieldToken;
    }

    function isValidTokenIn(address token) public view override returns (bool) {
        return token == yieldToken || token == asset || token == WETH;
    }
}
