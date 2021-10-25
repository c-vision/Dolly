//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;

interface IUniswapV2Factory {

    /// Emitted each time a pair is created via createPair.
    /// 
    /// token0 is guaranteed to be strictly less than token1 by sort order.
    /// The final uint log value will be 1 for the first pair created, 2 for the second, etc. 
    /// (see allPairs/getPair).
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    /// Protocol Fees
    /// At the moment there are no protocol fees. However, it is possible for a 0.05% fee to be turned 
    /// on in the future.
    /// 
    /// Protocol Charge Calculation
    /// In the future, it is possible that a protocol-wide charge of 0.05% per trade will take effect. 
    /// This represents ⅙th (16.6̅%) of the 0.30% fee. The fee is in effect if feeTo is not address(0) 
    /// (0x0000000000000000000000000000000000000000), indicating that feeTo is the recipient of the 
    /// charge.
    /// This amount would not affect the fee paid by traders, but would affect the amount received by 
    /// liquidity providers.
    /// Rather than calculating this charge on swaps, which would significantly increase gas costs for 
    /// all users, the charge is instead calculated when liquidity is added or removed. See the 
    /// whitepaper for more details.
    function feeTo() external view returns (address);

    /// The address allowed to change feeTo.
    function feeToSetter() external view returns (address);

    /// Returns the address of the pair for tokenA and tokenB, if it has been created, else address(0) 
    /// (0x0000000000000000000000000000000000000000).
    ///
    /// tokenA and tokenB are interchangeable.
    /// Pair addresses can also be calculated deterministically, see Pair Addresses.
    function getPair(address tokenA, address tokenB) external view returns (address pair);

    /// Returns the address of the nth pair (0-indexed) created through the factory, or address(0) 
    /// (0x0000000000000000000000000000000000000000) if not enough pairs have been created yet.
    ///
    /// Pass 0 for the address of the first pair created, 1 for the second, etc.
    function allPairs(uint) external view returns (address pair);

    /// Returns the total number of pairs created through the factory so far.
    function allPairsLength() external view returns (uint);

    /// Creates a pair for tokenA and tokenB if one doesn’t exist already.
    ///
    /// tokenA and tokenB are interchangeable.
    /// Emits PairCreated.
    function createPair(address tokenA, address tokenB) external returns (address pair);

    /// undocumented
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    
}
