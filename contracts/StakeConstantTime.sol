//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;

import "./OwnableExt.sol";

// Constant Time Fee Redistribution Smart Contract
// Bogdan BATOG
// December 11, 2017

// https://hackernoon.com/front-running-bancor-in-150-lines-of-python-with-ethereum-api-d5e2bfd0d798

// A "savings account" for cryptocurrencies is proposed in TokenBNK whitepaper, where funds from 
// withdrawal fees are used to reward holders. I explore the practical implementation of this 
// redistribution logic in a smart contract over Ethereum blockchain.

// Users can deposit and withdraw funds from the smart contract at any time. At withdrawal time, a fixed 
// percentage of the deposit will be retained and then redistributed proportionally to the remaining 
// deposits. The system thus incentivizes long term holding. In addition, the last one to withdraw will 
// not pay any fee, since there's no other destination to redistribute to. Note that duration of deposit 
// is not used to determine the fee neither the reward. It's only the relative order between withdrawals 
// that impacts the redistribution. Every user will pay a fixed percentage fee, so there's a clear bound 
// on the potential loss that may be encountered. Potential gain however, has no bound, as unlimited 
// amounts can be deposited by other users and then withdrawn, thus generating more reward for holders.

// Let's start by considering only one deposit per address. Later I'll also discuss multiple deposits 
// per address (successive addition to the original deposit). Instead, I'll only consider full 
// withdrawals. The withdrawal amount is computed as
//
//                  withdraw = principal - fee + reward
// 
// Let principalt denote the original deposited amount that is now asked for withdrawal at moment t. 
// Let T(t) be the sum of active deposits at moment t (before this withdrawal is processed).
// Let 0 < FP < 1 be a constant percentage, then the fee paid when withdrawing this deposit is
//
//                  fee(t) = FP * principal(t)
//
// The redistribution occurs at the withdrawal moment and it reallocates the collected fee to all other 
// active deposits, proportional to their principal amount. This means another deposit depositj will get 
// a proportional reward of:
// 
//                  reward(j, t) = principal(j) * (fee(t) / (T(t) - principal(t)))
//
// A simple implementation is to iterate over all active deposits and increase their stored reward. But 
// such a loop will require more gas per contract call as more deposits are created, making it a costly 
// approach. A more efficient implementation is possible, in O(1) time.
//
// The total reward earned by one deposit is the sum of proportional rewards it extracted from every 
// other withdrawal, while it was active.
// 
//      reward(j) = SUM(1, t)(reward(j, t)) = principal(j) * SUM(1, t)((fee(t) / (T(t) - principal(t))))
// 
// where t iterates over all withdrawals performed while deposit j was active. Let's note this sum, from 
// beginning of time until time t:
// 
//                      SUM(t)((fee(t) / (T(t) - principal(t)))) = S(t)
// 
// This means that if deposit j is created at moment t1 and then withdrawn at moment t2 > t1, its reward 
// is:
// 
//  reward(j) = principal(j) * SUM(t=t(1)+1, t(2))((fee(t) / (T(t) - principal(t)))) = principal(j) * (S(t2) - S(t1))
// 
// This form can be implemented in constant time by noting that St is monotonic.
//
contract StakeConstantTime {

    // https://uploads-ssl.webflow.com/5ad71ffeb79acc67c8bcdaba/5ad8d1193a40977462982470_scalable-reward-distribution-paper.pdf
    uint256 private T = 0;
    uint256 private S = 0;
    uint256 Fp = 2;
    uint128 Scale = 100; // (fp/Scale) = 1/1000 = 0.1%
    mapping(address => uint256) private deposit;
    mapping(address => uint256) private S0;

    event FeeObtained(uint256 fee, uint256 x, uint256 y, uint128 scale);
    event Deposited(uint256 amount);
    event Scaled(uint256 x, uint256 y, uint128 scale);
    event Withdrawed(address user, uint256 principal, uint256 fee, uint256 reward, uint256 amount);

    constructor() {
        T = 0;
        S = 0;
    }

    function Deposit(uint256 amount) public {
        deposit[msg.sender] = amount;
        S0[msg.sender] = S;
        T = T + amount;
        emit Deposited(amount);
    }

    // Calculate x * y / scale rounding down.
    function mulScale (uint256 x, uint256 y, uint128 scale) internal returns (uint) {
        emit Scaled(x, y, scale);
        uint a = x / scale;
        uint b = x % scale;
        uint c = y / scale;
        uint d = y % scale;
        return a * c * scale + a * d + b * c + b * d / scale;
    }

    function Withdraw() public returns (uint256) {
        uint256 principal = deposit[msg.sender];
        // Let 0 < FP < 1 be a constant percentage
        uint256 fee = mulScale(Fp,  principal, Scale);
        emit FeeObtained(fee, Fp, principal, Scale);
        uint256 reward = principal * (S - S0[msg.sender]);
        if (principal == T)
            fee = 0;
        else
            S = S + fee / (T - principal);
        T = T - principal;
        deposit[msg.sender] = 0;
        emit Withdrawed(msg.sender, principal, fee, reward, principal - fee + reward);
        return principal - fee + reward;
    }

}