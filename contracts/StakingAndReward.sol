// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

error Transfer_Failed();
error User_Has_Not_Staked_Any_Tokens();
error Not_An_Owner();
error Approved_Token_Balance_Not_Sufficient();
error Withdrawal_Of_Staking_Balance_And_Reward_Paused();
error Invalid_Amount_Entered();

//Find Alternative for block.timestamp Or use Chainlink
/**
 * @title StakingAndReward
 * @dev A smart contract that allows users to stake ERC20 tokens and earn rewards
 * in the same ERC20 token. The rewards are calculated based on the total amount of
 * tokens staked and the time period for which the tokens are staked.
 */

contract StakingAndReward is ReentrancyGuard {
    event TimeStamp_Updated(uint256 indexed timestamp, address indexed creator);
    event Token_Staked(uint256 indexed amount, address indexed staker);
    event Token_Withdrawal(uint256 indexed amount, address indexed withdrawer);
    event Withdrawal_Paused();
    event Rewards_Per_User_Updated(
        uint256 indexed updatedReward,
        address indexed user
    );
    event Reward_Rate_Updated(
        uint256 indexed newRewardRate,
        address indexed updater
    );
    event Reward_Period_Updated(
        uint256 indexed newRewardPeriod,
        address indexed updater
    );
    event Reward_Claimed(uint256 indexed reward, address indexed user);

    address payable public immutable i_owner;
    mapping(address => uint256) private stakersBalances;
    mapping(address => uint256) private latestTimeStamps;
    mapping(address => uint256) private rewardsPerUser;

    uint256 private totalStakedTokens = 0;
    IERC20 private immutable i_stakingToken;
    //pause feature would allow the contract owner to pause the contract in case of emergencies or unforeseen circumstances
    bool private pauseWithdrawalOfBalanceAndReward = false;
    // In 1 period  staking of 1000 tokens, will get rewardRate tokens as reward
    uint256 private rewardRate = 5; //rewardTokensPerPeriodPerThousandStaked
    //rewardPeriod in seconds ,you will get reward after each Period
    uint256 private rewardPeriod = 10;

    /**
     * @dev Constructor function that sets the contract owner and the staking token address.
     * @param tokenAddress The address of the ERC20 token that users will stake.
     */
    constructor(address tokenAddress) {
        i_owner = payable(msg.sender);
        i_stakingToken = IERC20(tokenAddress);
    }

    /**
     * @dev Modifier that allows only the contract owner to execute the function.
     */
    modifier onlyByOwner() {
        if (msg.sender != i_owner) {
            revert Not_An_Owner();
        }
        _;
    }
    /**
     * @dev Modifier that updates the reward for the user after executing the function.
     * @param user The address of the user whose reward is being updated.
     */
    modifier updateReward(address user) {
        uint256 newReward = getRewardToBeClaimed(user);
        latestTimeStamps[user] = block.timestamp;
        emit TimeStamp_Updated(block.timestamp, user);
        uint256 oldReward = rewardsPerUser[user];
        if (newReward > oldReward) {
            rewardsPerUser[user] = newReward;
            emit Rewards_Per_User_Updated(rewardsPerUser[user], user);
        }

        _;
    }

    /**
     * @dev Function that allows users to stake ERC20 tokens and earn rewards.
     * @param amount The amount of tokens to be staked.
     * @return A boolean indicating whether the transaction was successful.
     */
    function stake(
        uint256 amount
    ) public updateReward(msg.sender) returns (bool) {
        if (amount > i_stakingToken.allowance(msg.sender, address(this))) {
            revert Approved_Token_Balance_Not_Sufficient();
        } //is this redundant or necessary ??
        //error can also be reverted from token contract,but we will revert from here itself if this is the case.

        bool success = i_stakingToken.transferFrom(
            msg.sender,
            address(this),
            amount
        );

        stakersBalances[msg.sender] += amount;
        totalStakedTokens += amount;
        emit Token_Staked(amount, msg.sender);
        return success;
    }

    /**
     * @dev Withdraws `amount` staking tokens from the sender's balance and transfers them back to the sender's address.
     * @param amount The amount of staking tokens to withdraw.
     * @return A boolean indicating whether the operation was successful.
     *
     * Emits a {Token_Withdrawal} event indicating the amount of tokens withdrawn and the address of the sender.
     * The function also updates the staker's reward by calling the `updateReward` function before executing the withdrawal.
     */
    function withdraw(
        uint256 amount
    ) public nonReentrant updateReward(msg.sender) returns (bool) {
        if (stakersBalances[msg.sender] <= 0) {
            revert User_Has_Not_Staked_Any_Tokens();
        }
        if (pauseWithdrawalOfBalanceAndReward) {
            revert Withdrawal_Of_Staking_Balance_And_Reward_Paused();
        }
        if (amount > stakersBalances[msg.sender]) {
            revert Invalid_Amount_Entered();
        }

        stakersBalances[msg.sender] -= amount;

        totalStakedTokens -= amount;

        bool success = i_stakingToken.transfer(msg.sender, amount);
        if (!success) {
            revert Transfer_Failed();
        }
        //If success is true then,Transfer event will be emitted from transfer function of token contract,we can track that by their contract address
        emit Token_Withdrawal(amount, msg.sender);
        return success;
    }

    /**
     * @dev Allows a staker to claim their earned rewards.
     * @dev Throws an error if the staker has not staked any tokens.
     * @dev Throws an error if withdrawal of staking balance and reward is currently paused.
     */
    function claimRewards() public nonReentrant updateReward(msg.sender) {
        // Check if the user has staked any tokens
        if (stakersBalances[msg.sender] <= 0) {
            revert User_Has_Not_Staked_Any_Tokens();
        }

        // Check if withdrawal of staking balance and reward is currently paused
        if (pauseWithdrawalOfBalanceAndReward) {
            revert Withdrawal_Of_Staking_Balance_And_Reward_Paused();
        }

        //This will be updated in updateReward modifier
        uint256 reward = rewardsPerUser[msg.sender];

        // Set the staker's reward to zero
        rewardsPerUser[msg.sender] = 0;

        // Transfer the earned reward to the staker's address
        i_stakingToken.transfer(msg.sender, reward);

        // Emit a Reward_Claimed event to notify listeners of the reward claim
        emit Reward_Claimed(reward, msg.sender);
    }

    /**
     * @dev Allows the owner to pause or unpause withdrawal of staking balance and reward.
     * @param pause Boolean value representing whether withdrawal should be paused or not.
     */
    function setPauseWithdrawalOfBalanceAndReward(
        bool pause
    ) external onlyByOwner {
        pauseWithdrawalOfBalanceAndReward = pause;
    }

    /**
     * @dev Allows the owner to set the reward rate.
     * @param newRewardRate The new reward rate to be set.
     */
    function setRewardRate(uint256 newRewardRate) external onlyByOwner {
        rewardRate = newRewardRate;
    }

    /**
     * @dev Allows the owner to set the reward period.
     * @param newRewardDays The new reward period to be set.
     */
    function setRewardPeriod(uint256 newRewardDays) external onlyByOwner {
        rewardPeriod = newRewardDays;
    }

    /** View/Pure Functions */

    /**
     * @dev Calculates the reward amount that can be claimed by a user
     * @param user The address of the user
     * @return The reward amount in wei that can be claimed by the user
     */
    function getRewardToBeClaimed(address user) public view returns (uint256) {
        uint256 stakingTimeSeconds = block.timestamp - latestTimeStamps[user];

        uint256 staked = stakersBalances[user];

        //rewardPeriod in seconds
        uint256 totalStakingPeriods = uint(stakingTimeSeconds / rewardPeriod);

        return
            (uint(staked * totalStakingPeriods * rewardRate) / (1000)) +
            rewardsPerUser[user]; //returned in wei,we wil convert them using ethers.utils
    }

    /**
     * @dev Gets the current status of withdrawal of staking balance and reward
     * @return True if withdrawal of staking balance and reward is paused, false otherwise
     */
    function getPauseWithdrawalOfBalanceAndReward()
        external
        view
        returns (bool)
    {
        return pauseWithdrawalOfBalanceAndReward;
    }

    /**
     * @dev Gets the staked balance of a user
     * @param user The address of the user
     * @return The staked balance of the user
     */
    function getStakedBalanceOfUser(
        address user
    ) external view returns (uint256) {
        return stakersBalances[user];
    }

    /**
     * @dev Gets the total staked tokens in the contract
     * @return The total staked tokens in the contract
     */
    function getTotalStakedTokens() external view returns (uint256) {
        return totalStakedTokens;
    }

    /**
     * @dev Gets the total token balance held by the contract
     * @return The total token balance held by the contract
     */
    function getTotalContractTokenBalance() external view returns (uint256) {
        return i_stakingToken.balanceOf(address(this));
    }

    /**
     * @dev Gets the address of the staking token
     * @return The address of the staking token
     */
    function getStakingTokenAddress() external view returns (address) {
        return address(i_stakingToken);
    }

    /**
     * @dev Gets the latest timestamp of staking by a user
     * @param user The address of the user
     * @return The latest timestamp of staking by the user
     */
    function getLatestTimestamp(address user) external view returns (uint256) {
        return latestTimeStamps[user];
    }

    /**
     * @dev Gets the reward rate
     * @return The reward rate
     */
    function getRewardRate() external view returns (uint256) {
        return rewardRate;
    }

    /**
     * @dev Gets the reward period
     * @return The reward period in seconds
     */
    function getRewardPeriod() external view returns (uint256) {
        return rewardPeriod;
    }

    /**
     * @dev Gets the approved tokens that can be staked by the contract on behalf of an owner
     * @param ownerOfTokens The owner of the tokens
     * @return The approved tokens that can be staked by the contract on behalf of the owner
     */
    function getApprovedTokensToBeStaked(
        address ownerOfTokens
    ) external view returns (uint256) {
        return i_stakingToken.allowance(ownerOfTokens, address(this));
    }

    /**
     * @dev Gets the reward amount earned by a user
     * @param user The address of the user
     * @return The reward amount earned by the user in wei
     */
    function getUserReward(address user) external view returns (uint256) {
        return rewardsPerUser[user];
    }
}
