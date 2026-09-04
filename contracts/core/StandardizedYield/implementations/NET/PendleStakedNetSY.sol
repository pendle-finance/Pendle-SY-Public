// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../../v2/SYBaseUpgV2.sol";
import "../../../../interfaces/IPDecimalsWrapperFactory.sol";
import "../../../misc/TokenWithSupplyCapUpg.sol";
import "../../../../interfaces/NetNet/IStakedNet.sol";
import "../../../../interfaces/NetNet/IStakedNetStaking.sol";

contract PendleStakedNetSY is SYBaseUpgV2, TokenWithSupplyCapUpg {
    uint256 internal constant INDEX_BASE = 1e9;
    uint256 internal constant DECIMALS_OFFSET = 1e9;

    /// @dev mirror StakedNET's compile-time constants
    uint256 internal constant INITIAL_FRAGMENTS = 5_000_000_000e9;
    uint256 internal constant TOTAL_GONS = type(uint256).max - (type(uint256).max % INITIAL_FRAGMENTS);
    uint256 internal constant INDEX_GONS = INDEX_BASE * (TOTAL_GONS / INITIAL_FRAGMENTS);
    uint256 internal constant MAX_SNET_SUPPLY = type(uint128).max;

    address public immutable net;
    address public immutable sNet;
    address public immutable staking;
    address public immutable scaledNet;

    constructor(
        address _sNet,
        address _decimalsWrapperFactory
    ) SYBaseUpgV2(IPDecimalsWrapperFactory(_decimalsWrapperFactory).getOrCreate(_sNet, 18)) {
        sNet = _sNet;
        staking = IStakedNet(_sNet).staking();
        net = IStakedNetStaking(staking).net();

        scaledNet = IPDecimalsWrapperFactory(_decimalsWrapperFactory).getOrCreate(net, 18);
    }

    function initialize(string memory name_, string memory symbol_, address _owner) external initializer {
        __SYBaseUpgV2_init(name_, symbol_, _owner);
        _updateSupplyCap(type(uint256).max);
        _safeApproveInf(net, staking);
        _safeApproveInf(sNet, staking);
    }

    /*///////////////////////////////////////////////////////////////
                    DEPOSIT/REDEEM USING BASE TOKENS
    //////////////////////////////////////////////////////////////*/

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == net) {
            IStakedNetStaking(staking).stake(address(this), amountDeposited);
        }
        return (amountDeposited * DECIMALS_OFFSET * INDEX_BASE) / IStakedNet(sNet).index();
    }

    function _redeem(
        address receiver,
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal override returns (uint256 amountTokenOut) {
        if (tokenOut == net) {
            amountTokenOut = (amountSharesToRedeem * _syncedIndex()) / (DECIMALS_OFFSET * INDEX_BASE);
            IStakedNetStaking(staking).unstake(receiver, amountTokenOut);
        } else {
            amountTokenOut = (amountSharesToRedeem * IStakedNet(sNet).index()) / (DECIMALS_OFFSET * INDEX_BASE);
            _transferOut(sNet, receiver, amountTokenOut);
        }
    }

    /*///////////////////////////////////////////////////////////////
                               EXCHANGE-RATE
    //////////////////////////////////////////////////////////////*/

    function exchangeRate() external view virtual override returns (uint256) {
        uint256 index = _syncedIndex();
        return index * DECIMALS_OFFSET;
    }

    function _syncedIndex() internal view returns (uint256) {
        (, , uint64 epochEnd, uint256 queuedProfit) = IStakedNetStaking(staking).epoch();
        uint256 currentIndex = IStakedNet(sNet).index();
        if (block.timestamp < epochEnd || queuedProfit == 0) return currentIndex;

        uint256 supply = IStakedNet(sNet).totalSupply();
        uint256 circulating = supply - IStakedNet(sNet).balanceOf(staking);
        if (circulating == 0) return currentIndex;

        uint256 newSupply = supply + (queuedProfit * supply) / circulating;
        if (newSupply > MAX_SNET_SUPPLY) newSupply = MAX_SNET_SUPPLY;
        return INDEX_GONS / (TOTAL_GONS / newSupply);
    }

    /*///////////////////////////////////////////////////////////////
                MISC METADATA FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view override returns (uint256 /*amountSharesOut*/) {
        uint256 index = tokenIn == net ? _syncedIndex() : IStakedNet(sNet).index();
        return (amountTokenToDeposit * DECIMALS_OFFSET * INDEX_BASE) / index;
    }

    function _previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal view override returns (uint256 /*amountTokenOut*/) {
        uint256 index = tokenOut == net ? _syncedIndex() : IStakedNet(sNet).index();
        return (amountSharesToRedeem * index) / (DECIMALS_OFFSET * INDEX_BASE);
    }

    function getTokensIn() public view override returns (address[] memory res) {
        return ArrayLib.create(net, sNet);
    }

    function getTokensOut() public view override returns (address[] memory res) {
        return ArrayLib.create(net, sNet);
    }

    function isValidTokenIn(address token) public view override returns (bool) {
        return token == net || token == sNet;
    }

    function isValidTokenOut(address token) public view override returns (bool) {
        return token == net || token == sNet;
    }

    function assetInfo() external view returns (AssetType assetType, address assetAddress, uint8 assetDecimals) {
        return (AssetType.TOKEN, scaledNet, 18);
    }

    function pricingInfo() external view override returns (address refToken, bool refStrictlyEqual) {
        return (sNet, false);
    }

    /*///////////////////////////////////////////////////////////////
                               SUPPLY-CAP
    //////////////////////////////////////////////////////////////*/

    function getAbsoluteTotalSupply() external view returns (uint256) {
        return totalSupply();
    }

    function _afterTokenTransfer(address from, address, uint256) internal view override {
        if (from != address(0)) {
            return;
        }
        _checkSupplyCap(totalSupply());
    }
}
