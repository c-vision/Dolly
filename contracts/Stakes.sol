//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;

import "./OwnableExt.sol";

contract Stakes is OwnableExt {

    // addresses excluded from fees
    mapping (address => bool) private _isExcludedFromFee;

    // http://batog.info/papers/scalable-reward-distribution.pdf
    uint256 private T = 0;
    uint256 private S = 0;
    mapping(address => uint256) private stake;
    mapping(address => uint256) private S0;

    constructor() {
        T = 0;
        S = 0;
    }

    function Deposit(uint256 amount) public {
        stake[msg.sender] = amount;
        S0[msg.sender] = S;
        T = T + amount;
    }

    function Distruite(uint256 reward) public {
        if (T != 0)
            S = S + reward / T;
        else
            revert();
    }

    function Withdraw() public returns (uint256) {
        uint256 deposited = stake[msg.sender];
        uint256 reward = deposited * (S - S0[msg.sender]);
        T = T - deposited;
        stake[msg.sender] = 0;
        return deposited + reward;
    }

    /**
     *  check if the address is excluded from collecting fees
     */
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    
    /**
     *  exclude the address from collecting fees
     */
    function excludeFromFee(address account) public onlyOwnerOrAdmin {
        _isExcludedFromFee[account] = true;
    }
    
    /**
     *  include the address to collect fees
     */
    function includeInFee(address account) public onlyOwnerOrAdmin {
        _isExcludedFromFee[account] = false;
    }

}
