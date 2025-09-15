// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../v2/SYBaseUpgV2.sol";
import "../../../interfaces/IStakedHYPEOverseer.sol";
import "../../../interfaces/IStHYPE.sol";

contract PendleStakedHYPESY is SYBaseUpgV2 {
    address public constant stHYPE = 0xfFaa4a3D97fE9107Cef8a3F48c069F577Ff76cC1;
    address public constant wstHYPE = 0x94e8396e0869c9F2200760aF0621aFd240E1CF38;

    uint256 public constant balanceToSharesDecimal = 10 ** 6;
    uint256 public constant ONE_SHARE = 10 ** 24;
    address public constant OVERSEER = 0xB96f07367e69e86d6e9C3F29215885104813eeAE;

    constructor() SYBaseUpgV2(stHYPE) {}

    function initialize(string memory name_, string memory symbol_, address _owner) external initializer {
        __SYBaseUpgV2_init(name_, symbol_, _owner);
    }

    function _deposit(address tokenIn, uint256 amountDeposited) internal override returns (uint256 amountSharesOut) {
        if (tokenIn == wstHYPE) {
            amountSharesOut = amountDeposited;
        } else {
            if (tokenIn != stHYPE) {
                amountDeposited = IStakedHYPEOverseer(OVERSEER).mint{value: amountDeposited}(address(this));
            }
            amountSharesOut = IStHYPE(stHYPE).balanceToShares(amountDeposited) / balanceToSharesDecimal;
        }
    }

    function _redeem(
        address receiver,
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal override returns (uint256 amountTokenOut) {
        if (tokenOut == wstHYPE) {
            amountTokenOut = amountSharesToRedeem;
        } else {
            amountTokenOut = IStHYPE(stHYPE).sharesToBalance(amountSharesToRedeem * balanceToSharesDecimal);
        }

        _transferOut(tokenOut, receiver, amountTokenOut);
    }

    function exchangeRate() external view override returns (uint256 res) {
        return IStHYPE(stHYPE).sharesToBalance(ONE_SHARE);
    }

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view override returns (uint256 amountSharesOut) {
        if (tokenIn == wstHYPE) {
            amountSharesOut = amountTokenToDeposit;
        } else {
            amountSharesOut = IStHYPE(stHYPE).balanceToShares(amountTokenToDeposit) / balanceToSharesDecimal;
        }
    }

    function _previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal view override returns (uint256 amountTokenOut) {
        if (tokenOut == wstHYPE) {
            amountTokenOut = amountSharesToRedeem;
        } else {
            amountTokenOut = IStHYPE(stHYPE).sharesToBalance(amountSharesToRedeem * balanceToSharesDecimal);
        }
    }

    function getTokensIn() public pure override returns (address[] memory res) {
        return ArrayLib.create(NATIVE, stHYPE, wstHYPE);
    }

    function getTokensOut() public pure override returns (address[] memory res) {
        return ArrayLib.create(stHYPE, wstHYPE);
    }

    function isValidTokenIn(address token) public pure override returns (bool) {
        return token == NATIVE || token == stHYPE || token == wstHYPE;
    }

    function isValidTokenOut(address token) public pure override returns (bool) {
        return token == stHYPE || token == wstHYPE;
    }

    function assetInfo() external pure returns (AssetType assetType, address assetAddress, uint8 assetDecimals) {
        return (AssetType.TOKEN, NATIVE, 18);
    }

    function pricingInfo() external view override returns (address refToken, bool refStrictlyEqual) {
        return (yieldToken, false);
    }
}
