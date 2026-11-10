// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.34;

import "../PendleERC20SYUpgV2.sol";
import "../../../misc/TokenWithSupplyCapUpg.sol";

interface IPYieldTokenMinimal {
    function SY() external view returns (address);

    function mintPY(address receiverPT, address receiverYT) external returns (uint256);
}

/// @dev Merkl queues unbacked PT + YT, tracked as `creditDebt`. Mint cancellers can cancel before execution.
/// Burners burn the SY that `merkl` receives against `creditDebt`, so the USDe that buyers pay stays in the SY.
contract PendleEthenaCreditSY is PendleERC20SYUpgV2, TokenWithSupplyCapUpg {
    enum Role {
        MintCanceller,
        MintExecutor,
        Burner
    }

    struct QueuedMint {
        uint256 amount;
        uint256 readyAt;
    }

    address public yt;
    address public merkl;
    uint256 public creditDebt;

    QueuedMint public queuedMint;
    uint256 public mintDelay;
    bool public isSeeded;

    mapping(Role => mapping(address => bool)) public hasRole;

    bool private transient _mintingPY;

    uint256[100] private __gap;

    event MerklSet(address indexed merkl);
    event MintDelaySet(uint256 mintDelay);
    event RoleSet(Role indexed role, address indexed account, bool enabled);
    event MintQueued(uint256 amount, uint256 readyAt);
    event MintCancelled(uint256 amount);
    event MintExecuted(uint256 amount);
    event DebtBurned(uint256 amount);

    error YTAlreadySet();
    error YTMismatch();
    error NotMerkl();
    error NotRole(Role role);
    error MintNotReady();
    error AlreadySeeded();
    error SYTransferToYTLocked();

    modifier onlyMerkl() {
        require(msg.sender == merkl, NotMerkl());
        _;
    }

    modifier onlyRole(Role role) {
        require(hasRole[role][msg.sender], NotRole(role));
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
        mintDelay = 12 hours;
    }

    /// @dev Queueing again replaces the queued mint and restarts `mintDelay`.
    function queueMint(uint256 amount) external onlyMerkl {
        uint256 readyAt = block.timestamp + mintDelay;
        queuedMint = QueuedMint(amount, readyAt);
        emit MintQueued(amount, readyAt);
    }

    function cancelMint() external onlyRole(Role.MintCanceller) {
        emit MintCancelled(queuedMint.amount);
        delete queuedMint;
    }

    function executeMint() external onlyRole(Role.MintExecutor) nonReentrant {
        QueuedMint memory queued = queuedMint;
        require(block.timestamp >= queued.readyAt, MintNotReady());
        delete queuedMint;
        emit MintExecuted(queued.amount);

        creditDebt += queued.amount;
        _mintPY(queued.amount, merkl);
    }

    /// @dev The owner pays `amount` USDe, so this PT + YT carries no debt.
    function seed(uint256 amount) external onlyOwner nonReentrant {
        require(!isSeeded, AlreadySeeded());
        isSeeded = true;

        _transferIn(yieldToken, msg.sender, amount);
        _mintPY(amount, msg.sender);
    }

    function burnMerklSY() external onlyRole(Role.Burner) nonReentrant {
        uint256 amount = PMath.min(balanceOf(merkl), creditDebt);
        creditDebt -= amount;
        _burn(merkl, amount);
        emit DebtBurned(amount);
    }

    function setYT(address _yt) external onlyOwner {
        require(yt == address(0), YTAlreadySet());
        require(IPYieldTokenMinimal(_yt).SY() == address(this), YTMismatch());
        yt = _yt;
    }

    function setMerkl(address _merkl) external onlyOwner {
        merkl = _merkl;
        emit MerklSet(_merkl);
    }

    function setMintDelay(uint256 _mintDelay) external onlyOwner {
        mintDelay = _mintDelay;
        emit MintDelaySet(_mintDelay);
    }

    function setRole(Role role, address account, bool enabled) external onlyOwner {
        hasRole[role][account] = enabled;
        emit RoleSet(role, account, enabled);
    }

    function getAbsoluteTotalSupply() external view returns (uint256) {
        return totalSupply();
    }

    function _mintPY(uint256 amount, address receiver) private {
        _mintingPY = true;
        _mint(yt, amount);
        _mintingPY = false;

        IPYieldTokenMinimal(yt).mintPY(receiver, receiver);
    }

    /// @dev Anyone can mint PT + YT from SY sitting in the YT, so only `_mintPY` may put SY there.
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
