// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Adapter/extensions/PendleERC4626WithAdapterSY.sol";
import "../../../../interfaces/Instadapp/IInstaMerkle.sol";

contract PendleFluidLendingSY is PendleERC4626WithAdapterSY {
    address public constant INSTA_MERKLE = 0x3413D18500D5140095513d57a9Fcd9D882CbD064;
    address public constant FLUID = 0x61E030A56D33e8260FdD81f03B162A79Fe3449Cd;

    constructor(
        address _erc4626,
        address _offchainRewardManager
    ) PendleERC4626WithAdapterSY(_erc4626, _offchainRewardManager) {}

    function claimMerkle(
        address recipient_,
        uint256 cumulativeAmount_,
        uint8 positionType_,
        bytes32 positionId_,
        uint256 cycle_,
        bytes32[] calldata merkleProof_,
        bytes memory metadata_
    ) external onlyOwner {
        uint256 preBalance = _selfBalance(FLUID);
        IInstaMerkle(INSTA_MERKLE).claim(
            address(this),
            cumulativeAmount_,
            positionType_,
            positionId_,
            cycle_,
            merkleProof_,
            metadata_
        );
        _transferOut(FLUID, recipient_, _selfBalance(FLUID) - preBalance);
    }
}
