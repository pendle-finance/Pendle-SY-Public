// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../../../../erc20/PendleERC20Upg.sol";
import "../../../../libraries/BoringOwnableUpgradeableV2.sol";
import "../../../../misc/MerklRewardAbstract__NoStorage.sol";
import "../../../../../interfaces/Morpho/IPMorphoMarketWrapper.sol";
import {Id, MarketParams, IMorpho} from "../../../../../interfaces/Morpho/IMorpho.sol";
import {MorphoMarketLib} from "../libraries/MorphoMarketLib.sol";

contract PendleMorphoMarketWrapper is
    IPMorphoMarketWrapper,
    PendleERC20Upg,
    BoringOwnableUpgradeableV2,
    MerklRewardAbstract__NoStorage
{
    using MorphoMarketLib for MarketParams;

    /// @dev Mimics Morpho's VIRTUAL_SHARES, scaling down Morpho shares to the loan token's magnitude.
    uint256 public constant SHARE_SCALE = 1e6;

    IMorpho public immutable morpho;
    address public immutable loanToken;
    address public immutable collateralToken;
    address public immutable oracle;
    address public immutable irm;
    uint256 public immutable lltv;

    Id public immutable marketId;

    constructor(
        IMorpho _morpho,
        MarketParams memory marketParams_,
        address _offchainRewardManager
    )
        PendleERC20Upg(IERC20Metadata(marketParams_.loanToken).decimals())
        MerklRewardAbstract__NoStorage(_offchainRewardManager)
    {
        morpho = _morpho;

        loanToken = marketParams_.loanToken;
        collateralToken = marketParams_.collateralToken;
        oracle = marketParams_.oracle;
        irm = marketParams_.irm;
        lltv = marketParams_.lltv;

        marketId = marketParams_.id();

        _disableInitializers();
    }

    function initialize(string memory _name, string memory _symbol, address _owner) external initializer {
        __ERC20Upg_init(_name, _symbol);
        __BoringOwnableV2_init(_owner);
        _safeApproveInf(loanToken, address(morpho));
    }

    function deposit(uint256 assets) external nonReentrant returns (uint256 shares) {
        _transferIn(loanToken, msg.sender, assets);
        (, uint256 morphoShares) = morpho.supply(_marketParams(), assets, 0, address(this), "");
        shares = morphoShares / SHARE_SCALE;
        require(shares != 0, "PMMW: zero shares");
        _mint(msg.sender, shares);
    }

    function redeem(uint256 shares, address receiver) external nonReentrant returns (uint256 assets) {
        _burn(msg.sender, shares);
        (assets, ) = morpho.withdraw(_marketParams(), 0, shares * SHARE_SCALE, address(this), receiver);
    }

    function previewDeposit(uint256 assets) external view returns (uint256 shares) {
        (uint256 totalSupplyAssets, uint256 totalSupplyShares) = MorphoMarketLib.expectedSupplyBalances(
            morpho,
            _marketParams()
        );
        return MorphoMarketLib.toSharesDown(assets, totalSupplyAssets, totalSupplyShares) / SHARE_SCALE;
    }

    function previewRedeem(uint256 shares) public view returns (uint256 assets) {
        (uint256 totalSupplyAssets, uint256 totalSupplyShares) = MorphoMarketLib.expectedSupplyBalances(
            morpho,
            _marketParams()
        );
        return MorphoMarketLib.toAssetsDown(shares * SHARE_SCALE, totalSupplyAssets, totalSupplyShares);
    }

    function exchangeRate() external view returns (uint256) {
        return previewRedeem(MorphoMarketLib.WAD);
    }

    function sweepDust(address receiver) external onlyOwner returns (uint256) {
        uint256 positionShares = morpho.position(marketId, address(this)).supplyShares;
        uint256 dustShares = positionShares - totalSupply() * SHARE_SCALE;
        require(dustShares != 0, "PMMW: no dust");
        (uint256 dustAssets, ) = morpho.withdraw(_marketParams(), 0, dustShares, address(this), receiver);
        return dustAssets;
    }

    function rescueToken(address token, address to, uint256 amount) external onlyOwner {
        require(token != loanToken, "PMMW: loan token");
        _transferOut(token, to, amount);
    }

    function _marketParams() internal view returns (MarketParams memory) {
        return
            MarketParams({
                loanToken: loanToken,
                collateralToken: collateralToken,
                oracle: oracle,
                irm: irm,
                lltv: lltv
            });
    }
}
