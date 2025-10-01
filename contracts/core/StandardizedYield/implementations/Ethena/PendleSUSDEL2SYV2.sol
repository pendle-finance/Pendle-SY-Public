// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../PendleERC20SY.sol";
import "../../../../interfaces/IPTokenWithSupplyCap.sol";
import {AggregatorV2V3Interface as IChainlinkAggregator} from
    "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";
import {MerklRewardAbstract__NoStorage} from "../../../misc/MerklRewardAbstract__NoStorage.sol";

contract PendleSUSDEL2SYV2 is PendleERC20SY, MerklRewardAbstract__NoStorage, IPTokenWithSupplyCap {
    using PMath for uint256;
    using PMath for int256;

    event SupplyCapUpdated(uint256 newSupplyCap);

    error SupplyCapExceeded(uint256 totalSupply, uint256 supplyCap);

    address public immutable usde;
    address public immutable chainlinkExchangeRateOracle;
    uint256 public supplyCap;
    
    uint8 private immutable oracleDecimals;

    constructor(address _susde, address _usde, uint256 _initialSupplyCap, address _chainlinkExchangeRateOracle, address _offchainRewardManager)
        PendleERC20SY("SY Ethena sUSDE", "SY-sUSDE", _susde)
        MerklRewardAbstract__NoStorage(_offchainRewardManager)
    {
        usde = _usde;
        chainlinkExchangeRateOracle = _chainlinkExchangeRateOracle;
        _updateSupplyCap(_initialSupplyCap);
        oracleDecimals = IChainlinkAggregator(chainlinkExchangeRateOracle).decimals();
    }

    function exchangeRate() public view virtual override returns (uint256) {
        (, int256 latestAnswer,,,) = IChainlinkAggregator(chainlinkExchangeRateOracle).latestRoundData();
        return latestAnswer.Uint().divDown(10 ** oracleDecimals);
    }

    /*///////////////////////////////////////////////////////////////
                            SUPPLY CAP LOGIC
    //////////////////////////////////////////////////////////////*/

    function _previewDeposit(address, /*tokenIn*/ uint256 amountTokenToDeposit)
        internal
        view
        override
        returns (uint256 /*amountSharesOut*/ )
    {
        uint256 _newSupply = totalSupply() + amountTokenToDeposit;
        uint256 _supplyCap = supplyCap;

        if (_newSupply > _supplyCap) {
            revert SupplyCapExceeded(_newSupply, _supplyCap);
        }

        return amountTokenToDeposit;
    }

    function updateSupplyCap(uint256 newSupplyCap) external onlyOwner {
        _updateSupplyCap(newSupplyCap);
    }

    function _updateSupplyCap(uint256 newSupplyCap) internal {
        supplyCap = newSupplyCap;
        emit SupplyCapUpdated(newSupplyCap);
    }

    // @dev: whenNotPaused not needed as it has already been added to beforeTransfer
    function _afterTokenTransfer(address from, address, uint256) internal virtual override {
        // only check for minting case
        // saving gas on user->user transfers
        // skip supply cap checking on burn to allow lowering supply cap
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

    function assetInfo()
        external
        view
        virtual
        override
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.TOKEN, usde, IERC20Metadata(usde).decimals());
    }
}
