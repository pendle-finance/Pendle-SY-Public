// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IPExchangeRateOracle} from "../../interfaces/IPExchangeRateOracle.sol";
import {IERC4626} from "../../interfaces/IERC4626.sol";
import {ICentrifugeShareToken} from "../../interfaces/Centrifuge/ICentrifugeShareToken.sol";

/// @dev returns shareToken scaled18 -> asset scaled18, 18 decimals
contract PendleCentrifugeExchangeRateOracle is IPExchangeRateOracle {
    address public immutable shareToken;
    address public immutable asset;
    uint256 public immutable shareUnitScaled;

    constructor(address _shareToken, address _asset) {
        uint256 shareDecimals = IERC20Metadata(_shareToken).decimals();
        uint256 assetDecimals = IERC20Metadata(_asset).decimals();

        assert(shareDecimals <= 18);
        assert(assetDecimals <= 18);

        shareToken = _shareToken;
        asset = _asset;
        shareUnitScaled = 10 ** (shareDecimals + 18 - assetDecimals);
    }

    function getExchangeRate() external view returns (uint256) {
        return IERC4626(ICentrifugeShareToken(shareToken).vault(asset)).convertToAssets(shareUnitScaled);
    }
}
