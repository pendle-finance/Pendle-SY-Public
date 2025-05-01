// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../../../../interfaces/Cygnus/ICygnusStToken.sol";
import "../../../../interfaces/Cygnus/ICygnusWstToken.sol";

import "../../SYBaseUpg.sol";

contract PendleWcgUSDSY is SYBaseUpg {
    address public constant WCGUSD = 0x5AE84075F0E34946821A8015dAB5299A00992721;
    address public constant CGUSD = 0xCa72827a3D211CfD8F6b00Ac98824872b72CAb49;
    address public constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;

    address public constant REFEREE = 0x8119EC16F0573B7dAc7C0CB94EB504FB32456ee1;

    constructor() SYBaseUpg(WCGUSD) {}

    function initialize() external initializer {
        __SYBaseUpg_init("SY Wrapped Cygnus USD", "SY-wcgUSD");
        _safeApproveInf(USDC, CGUSD);
        _safeApproveInf(CGUSD, WCGUSD);
    }

    function _deposit(address tokenIn, uint256 amountDeposited) internal virtual override returns (uint256) {
        if (tokenIn == USDC) {
            ICygnusStToken(CGUSD).mint(REFEREE, amountDeposited);
            (tokenIn, amountDeposited) = (CGUSD, _selfBalance(CGUSD));
        }

        if (tokenIn == CGUSD) {
            return ICygnusWstToken(WCGUSD).wrap(amountDeposited);
        } else {
            return amountDeposited;
        }
    }

    function _redeem(
        address receiver,
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal virtual override returns (uint256 amountTokenOut) {
        if (tokenOut == CGUSD) {
            amountTokenOut = ICygnusWstToken(WCGUSD).unwrap(amountSharesToRedeem);
        }
        _transfer(tokenOut, receiver, amountTokenOut);
    }

    /*///////////////////////////////////////////////////////////////
                               EXCHANGE-RATE
    //////////////////////////////////////////////////////////////*/

    function exchangeRate() public view virtual override returns (uint256) {
        return ICygnusStToken(CGUSD).convertToAssets(1e18);
    }

    /*///////////////////////////////////////////////////////////////
                MISC FUNCTIONS FOR METADATA
    //////////////////////////////////////////////////////////////*/

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view override returns (uint256 amountSharesOut) {
        if (tokenIn == WCGUSD) {
            return amountTokenToDeposit;
        } else {
            return ICygnusStToken(CGUSD).previewDeposit(amountTokenToDeposit);
        }
    }

    function _previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal view override returns (uint256 amountTokenOut) {
        if (tokenOut == WCGUSD) {
            return amountSharesToRedeem;
        } else {
            return ICygnusStToken(CGUSD).previewRedeem(amountSharesToRedeem);
        }
    }

    function getTokensIn() public view virtual override returns (address[] memory) {
        return ArrayLib.create(USDC, CGUSD, WCGUSD);
    }

    function getTokensOut() public view virtual override returns (address[] memory) {
        return ArrayLib.create(CGUSD, WCGUSD);
    }

    function isValidTokenIn(address token) public view virtual override returns (bool) {
        return token == USDC || token == CGUSD || token == WCGUSD;
    }

    function isValidTokenOut(address token) public view virtual override returns (bool) {
        return token == CGUSD || token == WCGUSD;
    }

    function assetInfo() external view returns (AssetType assetType, address assetAddress, uint8 assetDecimals) {
        return (AssetType.TOKEN, CGUSD, IERC20Metadata(CGUSD).decimals());
    }
}
