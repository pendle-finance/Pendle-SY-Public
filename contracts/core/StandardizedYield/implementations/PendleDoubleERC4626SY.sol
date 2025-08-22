// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.23;

import "../v2/SYBaseUpgV2.sol";
import "../../../interfaces/IERC4626.sol";

contract PendleDoubleERC4626SY is SYBaseUpgV2 {
    address public immutable vault1;
    address public immutable vault0;
    address public immutable asset;
    uint256[100] private __gap;

    constructor(address _vault) SYBaseUpgV2(_vault) {
        vault1 = _vault;
        vault0 = IERC4626(_vault).asset();
        asset = IERC4626(vault0).asset();
    }

    function initialize(string memory name_, string memory symbol_, address _owner) external initializer {
        __SYBaseUpgV2_init(name_, symbol_, _owner);
        _safeApproveInf(asset, vault0);
        _safeApproveInf(vault0, vault1);
    }

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == asset) {
            (tokenIn, amountDeposited) = (vault0, IERC4626(vault0).deposit(amountDeposited, address(this)));
        }
        if (tokenIn == vault0) {
            (tokenIn, amountDeposited) = (vault1, IERC4626(vault1).deposit(amountDeposited, address(this)));
        }
        return amountDeposited;
    }

    function _redeem(
        address receiver,
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal override returns (uint256 amountTokenOut) {
        if (tokenOut == vault1) {
            _transferOut(vault1, receiver, amountSharesToRedeem);
            return amountSharesToRedeem;
        }

        if (tokenOut == vault0) {
            return IERC4626(vault1).redeem(amountSharesToRedeem, receiver, address(this));
        }

        return
            IERC4626(vault0).redeem(
                IERC4626(vault1).redeem(amountSharesToRedeem, address(this), address(this)),
                receiver,
                address(this)
            );
    }

    function exchangeRate() public view virtual override returns (uint256 res) {
        return IERC4626(vault0).convertToAssets(IERC4626(vault1).convertToAssets(PMath.ONE));
    }

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == asset) {
            (tokenIn, amountTokenToDeposit) = (vault0, IERC4626(vault0).previewDeposit(amountTokenToDeposit));
        }
        if (tokenIn == vault0) {
            (tokenIn, amountTokenToDeposit) = (vault1, IERC4626(vault1).previewDeposit(amountTokenToDeposit));
        }
        return amountTokenToDeposit;
    }

    function _previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal view virtual override returns (uint256 /*amountTokenOut*/) {
        if (tokenOut == vault1) {
            return amountSharesToRedeem;
        }

        if (tokenOut == vault0) {
            return IERC4626(vault1).previewRedeem(amountSharesToRedeem);
        }

        return IERC4626(vault0).previewRedeem(IERC4626(vault1).previewRedeem(amountSharesToRedeem));
    }

    function getTokensIn() public view virtual override returns (address[] memory res) {
        return ArrayLib.create(asset, vault0, vault1);
    }

    function getTokensOut() public view override returns (address[] memory res) {
        return ArrayLib.create(asset, vault0, vault1);
    }

    function isValidTokenIn(address token) public view virtual override returns (bool) {
        return token == asset || token == vault0 || token == vault1;
    }

    function isValidTokenOut(address token) public view override returns (bool) {
        return token == asset || token == vault0 || token == vault1;
    }

    function assetInfo()
        external
        view
        virtual
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.TOKEN, asset, IERC20Metadata(asset).decimals());
    }
}
