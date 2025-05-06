// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../PendleERC4626UpgSYV2.sol";
// import "../../../../interfaces/Level/ILevelMinter.sol";
import "../../../../interfaces/Level/ILevelMinterV2.sol";
import {AggregatorV2V3Interface as IChainlinkAggregator} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

contract PendleStakedLevelUSDSY is PendleERC4626UpgSYV2 {
    using PMath for uint256;
    using PMath for int256;

    address public constant SLVLUSD = 0x4737D9b4592B40d51e110b94c9C043c6654067Ae;
    address public constant LVLUSD = 0x7C1156E515aA1A2E851674120074968C905aAF37;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant LEVEL_MINTER = 0x8E7046e27D14d09bdacDE9260ff7c8c2be68a41f;

    constructor() PendleERC4626UpgSYV2(SLVLUSD) {}

    function initialize() external initializer {
        _safeApproveInf(USDT, LEVEL_MINTER);
        _safeApproveInf(asset, yieldToken);
        __SYBaseUpg_init("SY Staked lvlUSD", "SY-slvlUSD");
    }

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == USDT) {
            ILevelMinterV2(LEVEL_MINTER).mint(
                ILevelMinterV2.Order({
                    beneficiary: address(this),
                    collateral_asset: USDT,
                    collateral_amount: amountDeposited,
                    min_lvlusd_amount: 0
                })
            );
            (tokenIn, amountDeposited) = (LVLUSD, _selfBalance(LVLUSD));
        }
        return super._deposit(tokenIn, amountDeposited);
    }

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view virtual override returns (uint256 amountSharesOut) {
        if (tokenIn == USDT) {
            address oracle = ILevelMinterV2(LEVEL_MINTER).oracles(tokenIn);
            uint8 tokenInDecimals = IERC20Metadata(tokenIn).decimals();
            uint8 oracleDecimals = IChainlinkAggregator(oracle).decimals();

            uint256 price;
            {
                (, int256 _price, , , ) = IChainlinkAggregator(oracle).latestRoundData();
                price = _price.Uint().min(10 ** oracleDecimals);
            }

            tokenIn = LVLUSD;
            amountTokenToDeposit = (amountTokenToDeposit * price).divDown(10 ** (tokenInDecimals + oracleDecimals));
        }

        return super._previewDeposit(tokenIn, amountTokenToDeposit);
    }

    function isValidTokenIn(address token) public pure override returns (bool) {
        return token == LVLUSD || token == SLVLUSD || token == USDT;
    }

    function getTokensIn() public pure override returns (address[] memory res) {
        return ArrayLib.create(LVLUSD, SLVLUSD, USDT);
    }

    function isValidTokenOut(address token) public view virtual override returns (bool) {
        return token == yieldToken;
    }

    function getTokensOut() public view virtual override returns (address[] memory res) {
        res = new address[](1);
        res[0] = yieldToken;
    }
}
