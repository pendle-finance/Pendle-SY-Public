pragma solidity ^0.8.0;

interface IOETHVault {
    function mint(address _asset, uint256 _amount, uint256 _minimumOusdAmount) external;
}
