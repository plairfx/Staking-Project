// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title Staking Contract
 * @author plairfx
 * @notice Staking contracts that rewards users in token and gives them voting right.
 * Users are able to claim their rewards when the Chainlink Keeper calls the `earned` function.
 */
contract Staking is Ownable, Pausable, ReentrancyGuard {
    // INTERFACES
    IERC20 public stakedPlair;

    // Stakers Array
    address[] public stakingUsers;

    // Keeper Address
    address public keeper;

    // Staking Token & Reward Token.
    address private stakedAddr;

    uint256 public totalStaked;
    uint256 public totalUsers;
    uint256 public lastEarnTime;

    struct StakeData {
        uint256 stakedBalance;
        uint256 unlockTime;
        uint256 stakeTime;
        uint256 earned;
    }

    uint256 public UnlockTime;
    uint256 public lockTime;
    uint256 public MaxRewards;
    uint256 public TotalClaimed;

    uint256 immutable TotalRewardsPerDay = 7200;

    // Mappings

    mapping(address => StakeData) public stakers;
    mapping(address => uint256 EarnedRewards) public s_EarnedRewards;
    mapping(address => uint256 ClaimedTokens) public s_ClaimedTime;
    mapping(address => uint256 stakeTime) public StakingTime;

    // Modifiers
    modifier onlyKeeper() {
        require(msg.sender == keeper, "Caller is not the Keeper!");
        _;
    }

    // Events
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event LockTime(address indexed user, uint256 LockTime);

    constructor(address _stakedAddr, address newKeeper) Ownable(msg.sender) {
        stakedAddr = _stakedAddr;
        stakedPlair = IERC20(stakedAddr);
        keeper = newKeeper;
    }
    /**
     * @notice stakes the token and in return you accure rewards over a time-period.
     * @param _amount you want to stake.
     */

    function stake(uint256 _amount) external whenNotPaused {
        // Checks
        require(stakedPlair.balanceOf(msg.sender) >= _amount, "Not Enough Tokens");

        // Effects
        StakeData storage staker = stakers[msg.sender];
        staker.stakedBalance += _amount;
        staker.unlockTime = block.timestamp + (UnlockTime * 1 days);
        totalStaked += _amount;
        stakingUsers.push(msg.sender);

        // Interactions
        stakedPlair.transferFrom(msg.sender, address(this), _amount);

        emit Staked(msg.sender, _amount);
    }
    /**
     * @notice Unstakes the tokens you have staked in the 'Stake' Function.
     * @param _amount you want to unstake.
     */

    function unstake(uint256 _amount) external whenNotPaused {
        StakeData storage staker = stakers[msg.sender];

        require(staker.stakedBalance >= _amount, "You can't unstake more than have you staked");
        require(block.timestamp >= staker.unlockTime, "You can't unstake yet!");

        // Effects
        staker.stakedBalance -= _amount;

        totalStaked -= _amount;

        // Interactions
        stakedPlair.transfer(msg.sender, _amount);

        // Emitting event.
        emit Unstaked(msg.sender, _amount);
    }

    /**
     * @notice claims the reward you have accured over a time-period.
     * @notice rewarded will be allocated once every 24 hours.
     * @notice nonReentrant modifier is used,cause of the violation of CEI.
     */
    function claim() public nonReentrant {
        require(TotalClaimed <= MaxRewards);
        require(s_EarnedRewards[msg.sender] > 0);

        s_ClaimedTime[msg.sender] = block.timestamp;

        TotalClaimed += s_EarnedRewards[msg.sender];
        stakedPlair.transfer(msg.sender, s_EarnedRewards[msg.sender]);
        s_EarnedRewards[msg.sender] = 0;
    }

    /**
     * @notice calculates the rewards all of the users have earned
     * @dev this function can only be called by a Chainlink Keeper.
     */
    function earned() external onlyKeeper {
        require(block.timestamp >= lastEarnTime + TotalRewardsPerDay);
        require(totalStaked > 0);
        // Setting the ear
        lastEarnTime = block.timestamp;
        for (uint256 i = 0; i < stakingUsers.length; i++) {
            address user = stakingUsers[i];
            StakeData storage staker = stakers[user];
            s_EarnedRewards[user] = (staker.stakedBalance * TotalRewardsPerDay) / totalStaked;
        }
    }

    /////////////////////////
    /// Owner Functions//////
    /////////////////////////
    function setLockTime(uint256 _locktime) public onlyOwner {
        UnlockTime = _locktime;
    }

    function setStakingRewards(uint256 _stakingReward) public onlyOwner {
        MaxRewards = _stakingReward;
    }

    function setKeeper(address newKeeper) public onlyOwner {
        keeper = newKeeper;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    //////////////////
    /// GETTERS//////
    ////////////////

    function getStakedBalanceUser(address _user) external view returns (uint256) {
        return stakers[_user].stakedBalance;
    }

    function getUnlockTimeUser(address _user) external view returns (uint256) {
        return stakers[_user].unlockTime;
    }

    function getRewardsUser(address _user) external view returns (uint256) {
        return s_EarnedRewards[_user];
    }

    function getTotalStaked() external view returns (uint256) {
        return totalStaked;
    }

    function getTotalClaimed() external view returns (uint256) {
        return TotalClaimed;
    }

    function getMaxStakingReward() external view returns (uint256) {
        return MaxRewards;
    }

    function getKeeper() external view returns (address) {
        return keeper;
    }
}
