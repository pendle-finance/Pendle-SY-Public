// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../PendleERC4626SY.sol";
import "../../../../interfaces/Sky/ISkyConverter.sol";
import "../../../../interfaces/IPTokenWithSupplyCap.sol";

contract PendleSUSDSSY is PendleERC4626SY, IPTokenWithSupplyCap {
    address public constant SUSDS = 0xa3931d71877C0E7a3148CB7Eb4463524FEc27fbD;
    address public constant CONVERTER = 0x3225737a9Bbb6473CB4a45b7244ACa2BeFdB276A;
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant USDS = 0xdC035D45d973E3EC169d2276DDab16f1e407384F;

    uint256 public supplyCap;

    event SupplyCapUpdated(uint256 newSupplyCap);

    error SupplyCapExceeded(uint256 totalSupply, uint256 supplyCap);

    constructor() PendleERC4626SY("SY Savings USDS", "SY-sUSDS", SUSDS) {
        _safeApproveInf(DAI, CONVERTER);
        _safeApproveInf(USDS, CONVERTER);
        _updateSupplyCap(type(uint256).max);
    }

    function _deposit(address tokenIn, uint256 amountDeposited) internal virtual override returns (uint256) {
        if (tokenIn == DAI) {
            ISkyConverter(CONVERTER).daiToUsds(address(this), amountDeposited);
            return super._deposit(USDS, amountDeposited);
        }
        return super._deposit(tokenIn, amountDeposited);
    }

    function _redeem(
        address receiver,
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal override returns (uint256 amountTokenOut) {
        if (tokenOut == SUSDS) {
            amountTokenOut = amountSharesToRedeem;
            _transferOut(SUSDS, receiver, amountTokenOut);
        } else {
            if (tokenOut == USDS) {
                amountTokenOut = IERC4626(SUSDS).redeem(amountSharesToRedeem, receiver, address(this));
            } else {
                amountTokenOut = IERC4626(SUSDS).redeem(amountSharesToRedeem, address(this), address(this));
                ISkyConverter(CONVERTER).usdsToDai(receiver, amountTokenOut);
            }
        }
    }

    function getTokensIn() public view virtual override returns (address[] memory res) {
        res = new address[](3);
        res[0] = DAI;
        res[1] = USDS;
        res[2] = SUSDS;
    }

    function getTokensOut() public view virtual override returns (address[] memory res) {
        res = new address[](3);
        res[0] = DAI;
        res[1] = USDS;
        res[2] = SUSDS;
    }

    function isValidTokenIn(address token) public view virtual override returns (bool) {
        return token == DAI || token == USDS || token == SUSDS;
    }

    function isValidTokenOut(address token) public view virtual override returns (bool) {
        return token == DAI || token == USDS || token == SUSDS;
    }

    /*///////////////////////////////////////////////////////////////
                            SUPPLY CAP UPDATE
    //////////////////////////////////////////////////////////////*/

    function updateSupplyCap(uint256 newSupplyCap) external onlyOwner {
        _updateSupplyCap(newSupplyCap);
    }

    function _updateSupplyCap(uint256 newSupplyCap) internal {
        supplyCap = newSupplyCap;
        emit SupplyCapUpdated(newSupplyCap);
    }

    /*///////////////////////////////////////////////////////////////
                            SUPPLY CAP LOGIC
    //////////////////////////////////////////////////////////////*/

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view override returns (uint256 amountSharesOut) {
        amountSharesOut = super._previewDeposit(tokenIn, amountTokenToDeposit);
        uint256 _newSupply = totalSupply() + amountSharesOut;
        uint256 _supplyCap = supplyCap;

        if (_newSupply > _supplyCap) {
            revert SupplyCapExceeded(_newSupply, _supplyCap);
        }
    }

    function _afterTokenTransfer(address from, address, uint256) internal virtual override {
        if (from != address(0)) {
            return;
        }

        uint256 _supply = totalSupply();
        uint256 _supplyCap = supplyCap;
        if (_supply > _supplyCap) {
            revert SupplyCapExceeded(_supply, _supplyCap);
        }
    }

    function getAbsoluteSupplyCap() external view returns (uint256) {
        return supplyCap;
    }

    function getAbsoluteTotalSupply() external view returns (uint256) {
        return totalSupply();
    }
}
