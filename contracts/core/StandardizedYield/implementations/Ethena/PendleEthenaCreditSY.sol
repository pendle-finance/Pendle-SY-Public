// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.28;

import "../PendleERC20SYUpgV2.sol";
import "../../../misc/TokenWithSupplyCapUpg.sol";

interface IPYieldTokenMinimal {
    function SY() external view returns (address);

    function mintPY(address receiverPT, address receiverYT) external returns (uint256);
}

/// @dev The credit minter mints credit SY into PT + YT for `merkl`, tracked as `debt`.
/// The SY burner burns the SY that `merkl` receives against `debt`, so the USDe that buyers pay stays in the SY.
contract PendleEthenaCreditSY is PendleERC20SYUpgV2, TokenWithSupplyCapUpg {
    address public yt;
    address public merkl;
    address public creditMinter;
    address public syBurner;
    uint256 public debt;

    bool private transient _mintingPY;

    uint256[100] private __gap;

    event YTSet(address indexed yt);
    event MerklSet(address indexed merkl);
    event CreditMinterSet(address indexed creditMinter);
    event SyBurnerSet(address indexed syBurner);
    event MintPYCredit(uint256 amount);
    event DebtBurned(uint256 amount);

    error YTAlreadySet();
    error YTMismatch();
    error NotCreditMinter();
    error NotSyBurner();
    error SYTransferToYTLocked();

    modifier onlyCreditMinter() {
        require(msg.sender == creditMinter || msg.sender == owner, NotCreditMinter());
        _;
    }

    modifier onlySyBurner() {
        require(msg.sender == syBurner || msg.sender == owner, NotSyBurner());
        _;
    }

    constructor(address _usde) PendleERC20SYUpgV2(_usde) {}

    function initialize(
        string memory _name,
        string memory _symbol,
        address _owner,
        uint256 _initialSupplyCap
    ) external initializer {
        __SYBaseUpgV2_init(_name, _symbol, _owner);
        __tokenWithSupplyCap_init(_initialSupplyCap);
    }

    function setYT(address _yt) external onlyOwner {
        require(yt == address(0), YTAlreadySet());
        require(IPYieldTokenMinimal(_yt).SY() == address(this), YTMismatch());
        yt = _yt;
        emit YTSet(_yt);
    }

    function setMerkl(address _merkl) external onlyOwner {
        merkl = _merkl;
        emit MerklSet(_merkl);
    }

    function setCreditMinter(address _creditMinter) external onlyOwner {
        creditMinter = _creditMinter;
        emit CreditMinterSet(_creditMinter);
    }

    function setSyBurner(address _syBurner) external onlyOwner {
        syBurner = _syBurner;
        emit SyBurnerSet(_syBurner);
    }

    function mintPYCredit(uint256 amount) external onlyCreditMinter nonReentrant {
        _mintingPY = true;
        _mint(yt, amount);
        _mintingPY = false;

        IPYieldTokenMinimal(yt).mintPY(merkl, merkl);
        debt += amount;
        emit MintPYCredit(amount);
    }

    function burnMerklSY() external onlySyBurner nonReentrant {
        uint256 amount = PMath.min(balanceOf(merkl), debt);
        debt -= amount;
        _burn(merkl, amount);
        emit DebtBurned(amount);
    }

    function getAbsoluteTotalSupply() external view returns (uint256) {
        return totalSupply();
    }

    /// @dev Anyone can mint PT + YT from SY sitting in the YT, so only `mintPYCredit` may put SY there.
    /// `to == address(0)` lets burns through while `yt` is unset.
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        super._beforeTokenTransfer(from, to, amount);
        require(to != yt || to == address(0) || _mintingPY, SYTransferToYTLocked());
    }

    function _afterTokenTransfer(address from, address, uint256) internal view override {
        if (from != address(0)) {
            return;
        }
        _checkSupplyCap(totalSupply());
    }
}
