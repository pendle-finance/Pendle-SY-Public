// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "./PendleMorphoMetaVaultSY.sol";

contract PendleMorpho4626AssetSY is PendleMorphoMetaVaultSY {
    address public immutable vault;
    address public immutable erc4626;
    address public immutable erc4626Asset;

    constructor(
        string memory _name,
        string memory _symbol,
        address _vault
    ) PendleMorphoMetaVaultSY(_name, _symbol, _vault) {
        vault = _vault;
        erc4626 = IERC4626(_vault).asset();
        erc4626Asset = IERC4626(erc4626).asset();

        _safeApproveInf(erc4626Asset, erc4626);
    }

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == erc4626Asset) {
            (tokenIn, amountDeposited) = (erc4626, IERC4626(erc4626).deposit(amountDeposited, address(this)));
        }
        return super._deposit(tokenIn, amountDeposited);
    }

    function _redeem(
        address receiver,
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal virtual override returns (uint256 amountTokenOut) {
        if (tokenOut == erc4626Asset) {
            uint256 amount4626Out = IERC4626(vault).redeem(amountSharesToRedeem, address(this), address(this));
            return IERC4626(erc4626).redeem(amount4626Out, receiver, address(this));
        }
        return super._redeem(receiver, tokenOut, amountSharesToRedeem);
    }

    function exchangeRate() public view virtual override returns (uint256) {
        return IERC4626(erc4626).convertToAssets(IERC4626(vault).convertToAssets(PMath.ONE));
    }

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == erc4626Asset) {
            (tokenIn, amountTokenToDeposit) = (erc4626, IERC4626(erc4626).previewDeposit(amountTokenToDeposit));
        }
        return super._previewDeposit(tokenIn, amountTokenToDeposit);
    }

    function _previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal view override returns (uint256 amountTokenOut) {
        amountTokenOut = amountSharesToRedeem;
        if (tokenOut != yieldToken) {
            amountTokenOut = IERC4626(vault).previewRedeem(amountTokenOut);
            if (tokenOut == erc4626Asset) {
                amountTokenOut = IERC4626(erc4626).previewRedeem(amountTokenOut);
            }
        }
    }

    function getTokensIn() public view virtual override returns (address[] memory res) {
        return ArrayLib.create(erc4626Asset, erc4626, vault);
    }

    function getTokensOut() public view virtual override returns (address[] memory res) {
        return ArrayLib.create(erc4626Asset, erc4626, vault);
    }

    function isValidTokenIn(address token) public view virtual override returns (bool) {
        return token == erc4626Asset || token == erc4626 || token == vault;
    }

    function isValidTokenOut(address token) public view virtual override returns (bool) {
        return token == erc4626Asset || token == erc4626 || token == vault;
    }

    function assetInfo()
        external
        view
        virtual
        override
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.TOKEN, erc4626Asset, IERC20Metadata(erc4626Asset).decimals());
    }
}
