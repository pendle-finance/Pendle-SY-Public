// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../../v2/SYBaseUpgV2.sol";
import "../../../../interfaces/IPDecimalsWrapperFactory.sol";
import "../../../misc/TokenWithSupplyCapUpg.sol";
import "../../../../interfaces/Nuke/IStakedNuke.sol";
import "../../../../interfaces/Nuke/IStakedNukeStaking.sol";

contract PendleStakedNukeSY is SYBaseUpgV2, TokenWithSupplyCapUpg {
    uint256 internal constant INDEX_BASE = 1e9;
    uint256 internal constant DECIMALS_OFFSET = 1e9;

    /// @dev mirror StakedNUKE's compile-time constants
    uint256 internal constant INITIAL_FRAGMENTS = 5_000_000_000e9;
    uint256 internal constant TOTAL_GONS = type(uint256).max - (type(uint256).max % INITIAL_FRAGMENTS);
    uint256 internal constant INDEX_GONS = INDEX_BASE * (TOTAL_GONS / INITIAL_FRAGMENTS);
    uint256 internal constant MAX_SNUKE_SUPPLY = type(uint128).max;

    address public immutable nuke;
    address public immutable sNuke;
    address public immutable staking;
    address public immutable scaledNuke;

    constructor(
        address _sNuke,
        address _decimalsWrapperFactory
    ) SYBaseUpgV2(IPDecimalsWrapperFactory(_decimalsWrapperFactory).getOrCreate(_sNuke, 18)) {
        sNuke = _sNuke;
        staking = IStakedNuke(_sNuke).staking();
        nuke = IStakedNukeStaking(staking).nuke();

        scaledNuke = IPDecimalsWrapperFactory(_decimalsWrapperFactory).getOrCreate(nuke, 18);
    }

    function initialize(string memory name_, string memory symbol_, address _owner) external initializer {
        __SYBaseUpgV2_init(name_, symbol_, _owner);
        _updateSupplyCap(type(uint256).max);
        _safeApproveInf(nuke, staking);
        _safeApproveInf(sNuke, staking);
    }

    /*///////////////////////////////////////////////////////////////
                    DEPOSIT/REDEEM USING BASE TOKENS
    //////////////////////////////////////////////////////////////*/

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == nuke) {
            IStakedNukeStaking(staking).stake(address(this), amountDeposited);
        }
        return (amountDeposited * DECIMALS_OFFSET * INDEX_BASE) / IStakedNuke(sNuke).index();
    }

    function _redeem(
        address receiver,
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal override returns (uint256 amountTokenOut) {
        if (tokenOut == nuke) {
            amountTokenOut = (amountSharesToRedeem * _syncedIndex()) / (DECIMALS_OFFSET * INDEX_BASE);
            IStakedNukeStaking(staking).unstake(receiver, amountTokenOut);
        } else {
            amountTokenOut = (amountSharesToRedeem * IStakedNuke(sNuke).index()) / (DECIMALS_OFFSET * INDEX_BASE);
            _transferOut(sNuke, receiver, amountTokenOut);
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
        (, , uint64 epochEnd, uint256 queuedProfit) = IStakedNukeStaking(staking).epoch();
        uint256 currentIndex = IStakedNuke(sNuke).index();
        if (block.timestamp < epochEnd || queuedProfit == 0) return currentIndex;

        uint256 supply = IStakedNuke(sNuke).totalSupply();
        uint256 circulating = supply - IStakedNuke(sNuke).balanceOf(staking);
        if (circulating == 0) return currentIndex;

        uint256 newSupply = supply + (queuedProfit * supply) / circulating;
        if (newSupply > MAX_SNUKE_SUPPLY) newSupply = MAX_SNUKE_SUPPLY;
        return INDEX_GONS / (TOTAL_GONS / newSupply);
    }

    /*///////////////////////////////////////////////////////////////
                MISC METADATA FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view override returns (uint256 /*amountSharesOut*/) {
        uint256 index = tokenIn == nuke ? _syncedIndex() : IStakedNuke(sNuke).index();
        return (amountTokenToDeposit * DECIMALS_OFFSET * INDEX_BASE) / index;
    }

    function _previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal view override returns (uint256 /*amountTokenOut*/) {
        uint256 index = tokenOut == nuke ? _syncedIndex() : IStakedNuke(sNuke).index();
        return (amountSharesToRedeem * index) / (DECIMALS_OFFSET * INDEX_BASE);
    }

    function getTokensIn() public view override returns (address[] memory res) {
        return ArrayLib.create(nuke, sNuke);
    }

    function getTokensOut() public view override returns (address[] memory res) {
        return ArrayLib.create(nuke, sNuke);
    }

    function isValidTokenIn(address token) public view override returns (bool) {
        return token == nuke || token == sNuke;
    }

    function isValidTokenOut(address token) public view override returns (bool) {
        return token == nuke || token == sNuke;
    }

    function assetInfo() external view returns (AssetType assetType, address assetAddress, uint8 assetDecimals) {
        return (AssetType.TOKEN, scaledNuke, 18);
    }

    function pricingInfo() external view override returns (address refToken, bool refStrictlyEqual) {
        return (sNuke, false);
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
