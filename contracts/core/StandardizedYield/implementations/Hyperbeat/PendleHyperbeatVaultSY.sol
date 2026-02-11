// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../SYBaseUpg.sol";
import "../../../../interfaces/Hyperbeat/IHyperbeatDepositor.sol";
import "../../../../interfaces/Hyperbeat/IHyperbeatWithdrawalQueue.sol";
import "../../../../interfaces/Hyperbeat/IHyperbeatPricer.sol";

contract PendleHyperbeatVaultSY is SYBaseUpg {
    error SupplyCapExceeded(uint256 totalSupply, uint256 supplyCap);

    uint256 internal constant BASE = 1e4;

    address public immutable depositor;
    address public immutable withdrawalQueue;
    address public immutable pricer;
    address public immutable baseAsset;

    constructor(
        address _pricer,
        address _depositor,
        address _withdrawalQueue
    ) SYBaseUpg(IHyperbeatPricer(_pricer).vaultToken()) {
        depositor = _depositor;
        withdrawalQueue = _withdrawalQueue;
        pricer = _pricer;
        baseAsset = IHyperbeatPricer(pricer).baseAsset();
    }

    function initialize(string memory name_, string memory symbol_) external virtual initializer {
        __SYBaseUpg_init(name_, symbol_);
    }

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == yieldToken) {
            return amountDeposited;
        }

        uint256 balanceBefore = _selfBalance(yieldToken);
        _safeApproveInf(tokenIn, depositor);
        IHyperbeatDepositor(depositor).deposit(tokenIn, address(this), amountDeposited, PENDLE_REFERRER_ID());

        return _selfBalance(yieldToken) - balanceBefore;
    }

    function _redeem(
        address receiver,
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal override returns (uint256 amountTokenOut) {
        if (tokenOut == yieldToken) {
            _transferOut(tokenOut, receiver, amountSharesToRedeem);
            return amountSharesToRedeem;
        }

        uint256 balanceBefore = IERC20(tokenOut).balanceOf(receiver);
        IHyperbeatWithdrawalQueue(withdrawalQueue).instantWithdraw(receiver, amountSharesToRedeem);
        amountTokenOut = IERC20(tokenOut).balanceOf(receiver) - balanceBefore;
    }

    function exchangeRate() external view override returns (uint256 res) {
        return IHyperbeatPricer(pricer).getAssetAmount(baseAsset, PMath.ONE);
    }

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view override returns (uint256 amountSharesOut) {
        if (tokenIn == yieldToken) {
            return amountTokenToDeposit;
        }

        uint256 depositFee = IHyperbeatDepositor(depositor).depositFee();
        address depositFeeRecipient = IHyperbeatDepositor(depositor).depositFeeRecipient();
        uint256 depositCap = IHyperbeatDepositor(depositor).depositCap();

        if (depositFee != 0 && depositFeeRecipient != address(0)) {
            uint256 feeAmount = (amountTokenToDeposit * depositFee) / BASE;
            amountTokenToDeposit -= feeAmount;
        }

        amountSharesOut = IHyperbeatPricer(pricer).getVaultTokenAmount(tokenIn, amountTokenToDeposit);

        if (depositCap > 0) {
            uint256 newSupply = IERC20(yieldToken).totalSupply() + amountSharesOut;
            if (newSupply > depositCap) {
                revert SupplyCapExceeded(newSupply, depositCap);
            }
        }
    }

    function _previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal view override returns (uint256 amountTokenOut) {
        if (tokenOut == yieldToken) {
            return amountSharesToRedeem;
        }

        uint256 instantWithdrawalFee = IHyperbeatWithdrawalQueue(withdrawalQueue).instantWithdrawalFee();

        if (instantWithdrawalFee != 0) {
            uint256 feeAmount = PMath.rawDivUp(amountSharesToRedeem * instantWithdrawalFee, BASE);
            amountSharesToRedeem -= feeAmount;
        }

        amountTokenOut = IHyperbeatPricer(pricer).getAssetAmount(tokenOut, amountSharesToRedeem);
    }

    function getTokensIn() public view virtual override returns (address[] memory res) {
        return ArrayLib.create(yieldToken, baseAsset);
    }

    function getTokensOut() public view virtual override returns (address[] memory res) {
        return ArrayLib.create(yieldToken, baseAsset);
    }

    function isValidTokenIn(address token) public view virtual override returns (bool) {
        return token == yieldToken || IHyperbeatDepositor(depositor).isDepositToken(token);
    }

    function isValidTokenOut(address token) public view virtual override returns (bool) {
        return token == yieldToken || token == baseAsset;
    }

    function assetInfo() external view returns (AssetType assetType, address assetAddress, uint8 assetDecimals) {
        return (AssetType.TOKEN, baseAsset, IERC20Metadata(baseAsset).decimals());
    }

    /// @dev keccak256("hyperbeat.referrers.pendle")
    function PENDLE_REFERRER_ID() public pure returns (bytes32) {
        return 0x2a176b24a5fec3af048070ad484d82fe4152c8b8eb2edc993ef5700c58ef3d53;
    }
}
