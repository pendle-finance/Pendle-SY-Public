// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/BoringOwnableUpgradeableV2.sol";
import "../../interfaces/IPTokenWithSupplyCap.sol";
import "../../interfaces/IPExternalCapGates.sol";

/**
 * @title PendleExternalCapGates
 * @notice Registry contract for managing external cap contracts associated with SY tokens
 * @dev This contract acts as a gateway to retrieve supply cap information from external contracts
 */
contract PendleExternalCapGates is IPExternalCapGates, BoringOwnableUpgradeableV2 {
    event ExternalCapSet(address indexed sy, address indexed externalCapContract);

    mapping(address => address) public externalCapContracts;

    constructor(address _owner) initializer {
        __BoringOwnableV2_init(_owner);
    }

    function setExternalCapContract(address sy, address _newExternalCap) external onlyOwner {
        address _oldExternalCap = externalCapContracts[sy];
        require(_newExternalCap != _oldExternalCap, "PECG: invalid external cap");
        externalCapContracts[sy] = _newExternalCap;
        emit ExternalCapSet(sy, _newExternalCap);
    }

    function getAbsoluteSupplyCap(address sy) public view returns (uint256) {
        address externalCap = externalCapContracts[sy];
        require(externalCap != address(0), "PECG: not set");
        return IPTokenWithSupplyCap(externalCap).getAbsoluteSupplyCap();
    }

    function getAbsoluteTotalSupply(address sy) public view returns (uint256) {
        address externalCap = externalCapContracts[sy];
        require(externalCap != address(0), "PECG: not set");
        return IPTokenWithSupplyCap(externalCap).getAbsoluteTotalSupply();
    }
}
