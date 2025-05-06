// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../PendleERC20SYUpg.sol";
// import "../../../../interfaces/Level/ILevelMinter.sol";
import "../../../../interfaces/Level/ILevelMinterV2.sol";
import "../../../../interfaces/Level/ILevelVaultManagerV2.sol";
import {AggregatorV2V3Interface as IChainlinkAggregator} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

contract PendleLevelUSDSY is PendleERC20SYUpg {
    using PMath for uint256;
    using PMath for int256;

    address public constant LVLUSD = 0x7C1156E515aA1A2E851674120074968C905aAF37;
    
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;


    address public constant LEVEL_MINTER = 0x9136aB0294986267b71BeED86A75eeb3336d09E1;

    constructor() PendleERC20SYUpg(LVLUSD) {}

    function initialize() external initializer {
        _safeApproveInf(USDT, LEVEL_MINTER);
        __SYBaseUpg_init("SY Level USD", "SY-lvlUSD");
    }

    function approveForVault() onlyOwner external {
        address vault = ILevelVaultManagerV2(ILevelMinterV2(LEVEL_MINTER).vaultManager()).vault();
        _safeApproveInf(USDT, vault);
        _safeApproveInf(USDC, vault);
    }
    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == USDT || tokenIn == USDC) {
            uint256 preBalance = _selfBalance(LVLUSD);
            ILevelMinterV2(LEVEL_MINTER).mint(
                ILevelMinterV2.Order({
                    beneficiary: address(this),
                    collateral_asset: tokenIn,
                    collateral_amount: amountDeposited,
                    min_lvlusd_amount: 0
                })
            );
            return _selfBalance(LVLUSD) - preBalance;
        }
        return amountDeposited;
    }

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view virtual override returns (uint256 amountSharesOut) {
        if (tokenIn == LVLUSD) {
            return amountTokenToDeposit;
        }

        address oracle = ILevelMinterV2(LEVEL_MINTER).oracles(tokenIn);
        uint8 tokenInDecimals = IERC20Metadata(tokenIn).decimals();
        uint8 oracleDecimals = IChainlinkAggregator(oracle).decimals();

        uint256 price;
        {
            (, int256 _price, , , ) = IChainlinkAggregator(oracle).latestRoundData();
            price = _price.Uint().min(10 ** oracleDecimals);
        }

        return (amountTokenToDeposit * price).divDown(10 ** (tokenInDecimals + oracleDecimals));
    }

    function isValidTokenIn(address token) public pure override returns (bool) {
        return token == LVLUSD || token == USDT || token == USDC;
    }

    function getTokensIn() public pure override returns (address[] memory res) {
        return ArrayLib.create(LVLUSD, USDT, USDC);
    }
}
