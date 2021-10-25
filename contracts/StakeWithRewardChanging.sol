//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;

import "./OwnableExt.sol";

contract StakeWithRewardChanging is OwnableExt {

    // https://solmaz.io/2019/02/24/scalable-reward-changing/
    uint256 private total_stake = 0;
    uint256 private reward_per_token = 0;
    mapping(address => uint256) private stake;
    mapping(address => uint256) private reward_tally;

    constructor() {
        total_stake = 0;
        reward_per_token = 0;
    }

    function Deposit(uint256 amount) public {
        stake[msg.sender] = stake[msg.sender] + amount;
        reward_tally[msg.sender] = reward_tally[msg.sender] + reward_per_token * amount;
        total_stake = total_stake + amount;
    }

    function Distribute(uint256 reward) public {
        require(total_stake > 0, "Cannot distribute to staking pool with 0 stake");
        reward_per_token = reward_per_token + reward / total_stake;        
    }

    function ComputeReward() public view returns (uint256) {
        return stake[msg.sender] * reward_per_token - reward_tally[msg.sender];        
    }

    function WithdrawStake(uint256 amount) public returns (uint256) {
        require(stake[msg.sender] > 0, "Stake not found for given address");
        require(stake[msg.sender] > amount, "Requested amount greater than staked amount");
        stake[msg.sender] = stake[msg.sender] - amount;
        reward_tally[msg.sender] = reward_tally[msg.sender] - reward_per_token * amount;
        total_stake = total_stake - amount;
        return amount;
    }

    function WithdrawReward() public returns (uint256) {
        uint256 reward = ComputeReward();
        reward_tally[msg.sender] = stake[msg.sender] * reward_per_token;
        return reward;        
    }

}
