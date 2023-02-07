// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


struct Schedule {
    uint256 added;
    uint256 release;
    uint256 balance;
}

contract StakingContract is ERC20 {

    address private immutable _token;
    address private immutable _self;
    uint256 constant private rate = 1;

    mapping(address => Schedule) private _schedule;

    constructor(address token) ERC20(
        "Staking",
        "SK"
    ) {
        require(token != address(0), "constructor: Invalid address");
        _token = token;
        _self = address(this);
    }

    function stake(uint8 period, uint256 amount) external {
        require(period >= 21, "Stake: Invalid period");
        require(period <= 365, "Stake: Invalid period");

        SafeERC20.safeTransferFrom(IERC20(_token), msg.sender, _self, amount);
        _schedule[msg.sender] = Schedule(block.timestamp, block.timestamp + period, amount);

        emit Staked(msg.sender, amount);
    }

    function unstake() external {
        require(_schedule[msg.sender].release > block.timestamp, "UnStake: Invalid period");

        uint256 amount = _schedule[msg.sender].balance;
        require(amount > 0, "UnStake: Invalid balance");
        
        _schedule[msg.sender].balance = 0;
        _schedule[msg.sender].release = block.timestamp;

        SafeERC20.safeTransferFrom(IERC20(_token), _self, msg.sender, amount);

        emit UnStaked(msg.sender, amount);
    }

    function withdrawYeild() external {
        Schedule memory schedule = _schedule[msg.sender];

        require(block.timestamp > schedule.added + 28 days);

        uint256 amount = schedule.balance;
        amount += _calculateYeild(msg.sender);
        schedule.added = block.timestamp;
        schedule.balance = 0;

        _mint(msg.sender, amount);
    }

    function calculateMyYeild(address account) external {
        _calculateYeild(account);
    }

    function calculateYeild(address account) external {
        _calculateYeild(account);
    }

    function _calculateYeild(address account) private view returns (uint256) {
        assert(account != address(0));

        uint256 period = block.timestamp - _schedule[account].added;
        return _schedule[msg.sender].balance * period * rate;
    }

    event Staked (address indexed who, uint256 amount);
    event UnStaked (address indexed who, uint256 amount);
}