// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "./LibMoonwell.sol";
import "../../SYBaseWithRewardsUpg.sol";
import "../../../../interfaces/IPTokenWithSupplyCap.sol";
import "../../../../interfaces/Moonwell/IMToken.sol";

contract PendleMoonwellTokenBaseSY is SYBaseWithRewardsUpg, IPTokenWithSupplyCap {
    using PMath for uint256;

    error MoonwellMintError(uint256 errorCode);
    error MoonwellRedeemError(uint256 errorCode);
    error PendingRewardNonZero(address rewardToken, uint256 amount);

    uint256 public constant NO_ERROR = 0;

    address public constant WELL = 0xA88594D404727625A9437C3f886C7643872296AE;
    address public constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;

    address public immutable underlying;
    address public immutable comptroller;
    address public immutable rewardDistributor;

    constructor(address _mToken) SYBaseUpg(_mToken) {
        assert(block.chainid == 8453);
        comptroller = IMToken(_mToken).comptroller();
        underlying = IMToken(_mToken).underlying();
        rewardDistributor = IMComptroller(comptroller).rewardDistributor();
    }

    function initialize(string memory _name, string memory _symbol) external initializer {
        __SYBaseUpg_init(_name, _symbol);
        _safeApproveInf(underlying, yieldToken);
    }

    function _deposit(address tokenIn, uint256 amountDeposited) internal virtual override returns (uint256) {
        if (tokenIn == yieldToken) {
            return amountDeposited;
        }

        uint256 preBalance = _selfBalance(yieldToken);
        uint256 errCode;
        if ((errCode = IMErc20(yieldToken).mint(amountDeposited)) != NO_ERROR) {
            revert MoonwellMintError(errCode);
        }
        return _selfBalance(yieldToken) - preBalance;
    }

    function _redeem(
        address receiver,
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal virtual override returns (uint256 amountTokenOut) {
        if (tokenOut == yieldToken) {
            _transferOut(yieldToken, receiver, amountSharesToRedeem);
            return amountSharesToRedeem;
        } else {
            uint256 errCode;
            if ((errCode = IMErc20(yieldToken).redeem(amountSharesToRedeem)) != NO_ERROR) {
                revert MoonwellRedeemError(errCode);
            }
            _transferOut(underlying, receiver, amountTokenOut = _selfBalance(underlying));
            return amountTokenOut;
        }
    }

    /*///////////////////////////////////////////////////////////////
                               EXCHANGE-RATE
    //////////////////////////////////////////////////////////////*/

    function exchangeRate() public view virtual override returns (uint256) {
        return LibMoonwell.viewExchangeRate(IMErc20(yieldToken));
    }

    /*///////////////////////////////////////////////////////////////
                               REWARDS-RELATED
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See {IStandardizedYield-getRewardTokens}
     */
    function _getRewardTokens() internal pure override returns (address[] memory) {
        return ArrayLib.create(WELL, USDC);
    }

    function _redeemExternalReward() internal override {
        IMComptroller(comptroller).claimReward(address(this), ArrayLib.create(yieldToken));

        IMRewardDistributor.RewardInfo[] memory pendingRewards = IMRewardDistributor(rewardDistributor)
            .getOutstandingRewardsForUser(yieldToken, address(this));
        for (uint256 i = 0; i < pendingRewards.length; ++i) {
            if (pendingRewards[i].supplySide > 0) {
                revert PendingRewardNonZero(pendingRewards[i].emissionToken, pendingRewards[i].supplySide);
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                MISC FUNCTIONS FOR METADATA
    //////////////////////////////////////////////////////////////*/

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view override returns (uint256 amountSharesOut) {
        if (tokenIn == yieldToken) return amountTokenToDeposit;
        return amountTokenToDeposit.divDown(_viewExchangeRate());
    }

    function _previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal view override returns (uint256 amountTokenOut) {
        if (tokenOut == yieldToken) return amountSharesToRedeem;
        return amountSharesToRedeem.mulDown(_viewExchangeRate());
    }

    function getTokensIn() public view virtual override returns (address[] memory) {
        return ArrayLib.create(underlying, yieldToken);
    }

    function getTokensOut() public view virtual override returns (address[] memory) {
        return ArrayLib.create(underlying, yieldToken);
    }

    function isValidTokenIn(address token) public view virtual override returns (bool) {
        return token == yieldToken || token == underlying;
    }

    function isValidTokenOut(address token) public view virtual override returns (bool) {
        return token == yieldToken || token == underlying;
    }

    function assetInfo() external view returns (AssetType assetType, address assetAddress, uint8 assetDecimals) {
        return (AssetType.TOKEN, underlying, IERC20Metadata(underlying).decimals());
    }

    // In underlying asset unit
    function getAbsoluteSupplyCap() external view virtual returns (uint256) {
        uint256 cap = IMComptroller(comptroller).supplyCaps(yieldToken);
        if (cap == 0) {
            return type(uint256).max;
        }
        return cap;
    }

    function getAbsoluteTotalSupply() external view virtual returns (uint256) {
        return IERC20(yieldToken).totalSupply().mulDown(_viewExchangeRate());
    }

    function _viewExchangeRate() internal view returns (uint256) {
        return LibMoonwell.viewExchangeRate(IMErc20(yieldToken));
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        require(amount > 0, "transfer zero amount");
    }
}
