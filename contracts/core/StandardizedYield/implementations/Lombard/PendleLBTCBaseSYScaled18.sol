// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.23;

import "../../SYBaseUpg.sol";
import "../../../../interfaces/IStandardizedYieldExtended.sol";
import "../../../../interfaces/IPExchangeRateOracle.sol";
import "../../../../interfaces/Lombard/ILBTCMinterBase.sol";
import "../../../../interfaces/IPDecimalsWrapperFactory.sol";
import "../../../../interfaces/IPDecimalsWrapper.sol";

contract PendleLBTCBaseSYScaled18 is SYBaseUpg, IStandardizedYieldExtended {
    // solhint-disable immutable-vars-naming
    // solhint-disable const-name-snakecase
    // solhint-disable ordering

    address public constant CBBTC = 0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf;
    address public constant LBTC = 0xecAc9C5F704e954931349Da37F60E39f515c11c1;

    address public immutable wrapper;
    address public immutable CBBTCWrapper;

    constructor(address _wrapperFactory) SYBaseUpg(IPDecimalsWrapperFactory(_wrapperFactory).getOrCreate(LBTC, 18)) {
        wrapper = yieldToken;
        CBBTCWrapper = IPDecimalsWrapperFactory(_wrapperFactory).getOrCreate(CBBTC, 18);
    }

    function initialize() external initializer {
        __SYBaseUpg_init("SY Lombard LBTC scaled18", "SY-LBTC-scaled18");
        _safeApproveInf(LBTC, wrapper);
    }

    /*///////////////////////////////////////////////////////////////
                    DEPOSIT/REDEEM USING BASE TOKENS
    //////////////////////////////////////////////////////////////*/

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == wrapper) {
            // POC only, should never use wrapper to deposit
            return amountDeposited;
        }

        return IPDecimalsWrapper(wrapper).wrap(amountDeposited);
    }

    function _redeem(
        address receiver,
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal override returns (uint256) {
        if (tokenOut == wrapper) {
            // POC only, should never use wrapper to redeem
            _transferOut(wrapper, receiver, amountSharesToRedeem);
            return amountSharesToRedeem;
        } else {
            uint256 amountLBTC = IPDecimalsWrapper(wrapper).unwrap(amountSharesToRedeem);
            _transferOut(LBTC, receiver, amountLBTC);
            return amountLBTC;
        }
    }

    /*///////////////////////////////////////////////////////////////
                               EXCHANGE-RATE
    //////////////////////////////////////////////////////////////*/

    function exchangeRate() public view virtual override(SYBaseUpg, IStandardizedYield) returns (uint256) {
        return PMath.ONE;
    }

    /*///////////////////////////////////////////////////////////////
                MISC FUNCTIONS FOR METADATA
    //////////////////////////////////////////////////////////////*/

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view virtual override returns (uint256 amountSharesOut) {
        if (tokenIn == wrapper) {
            // POC only, should never use wrapper to deposit
            return amountTokenToDeposit;
        }

        return IPDecimalsWrapper(wrapper).rawToWrapped(amountTokenToDeposit);
    }

    function _previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal view virtual override returns (uint256 /*amountTokenOut*/) {
        if (tokenOut == wrapper) {
            // POC only, should never use wrapper to redeem
            return amountSharesToRedeem;
        } else {
            return IPDecimalsWrapper(wrapper).wrappedToRaw(amountSharesToRedeem);
        }
    }

    function getTokensIn() public view override(SYBaseUpg, IStandardizedYield) returns (address[] memory res) {
        return ArrayLib.create(LBTC, wrapper);
    }

    function getTokensOut() public view override(SYBaseUpg, IStandardizedYield) returns (address[] memory res) {
        return ArrayLib.create(LBTC, wrapper);
    }

    function isValidTokenIn(address token) public view override(SYBaseUpg, IStandardizedYield) returns (bool) {
        return token == LBTC || token == wrapper;
    }

    function isValidTokenOut(address token) public view override(SYBaseUpg, IStandardizedYield) returns (bool) {
        return token == LBTC || token == wrapper;
    }

    function assetInfo()
        external
        view
        virtual
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.TOKEN, CBBTCWrapper, 18);
    }

    function pricingInfo() external pure returns (address refToken, bool refStrictlyEqual) {
        return (LBTC, true);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        require(amount > 0, "transfer zero amount");
    }
}
