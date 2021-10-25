//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;

// When providing liquidity from a smart contract, the most important thing to keep in mind is that 
// tokens deposited into a pool at any rate other than the current reserve ratio are vulnerable to 
// being arbitraged. As an example, if the ratio of x:y in a pair is 10:2 (i.e. the price is 5), and 
// someone naively adds liquidity at 5:2 (a price of 2.5), the contract will simply accept all tokens 
// (changing the price to 3.75 and opening up the market to arbitrage), but only issue pool tokens 
// entitling the sender to the amount of assets sent at the proper ratio, in this case 5:1. To avoid 
// donating to arbitrageurs, it is imperative to add liquidity at the current price. Luckily, it’s 
// easy to ensure that this condition is met!
// 
// The easiest way to safely add liquidity to a pool is to use the router, which provides simple 
// methods to safely add liquidity to a pool. If the liquidity is to be added to an ERC-20/ERC-20 
// pair, use addLiquidity. If WETH is involved, use addLiquidityETH.
//
// These methods both require the caller to commit to a belief about the current price, which is 
// encoded in the amount*Desired parameters. Typically, it’s fairly safe to assume that the current 
// fair market price is around what the current reserve ratio is for a pair (because of arbitrage). 
// So, if a user wants to add 1 ETH to a pool, and the current DAI/WETH ratio of the pool is 200/1, 
// it’s reasonable to calculate that 200 DAI must be sent along with the ETH, which is an implicit 
// commitment to the price of 200 DAI/1 WETH. However, it’s important to note that this must be 
// calculated before the transaction is submitted. It is not safe to look up the reserve ratio from 
// within a transaction and rely on it as a price belief, as this ratio can be cheaply manipulated 
// to your detriment.
//
// However, it is still possible to submit a transaction which encodes a belief about the price which 
// ends up being wrong because of a larger change in the true market price before the transaction is 
// confirmed. For that reason, it’s necessary to pass an additional set of parameters which encode 
// the caller’s tolerance to price changes. These amount*Min parameters should typically be set to 
// percentages of the calculated desired price. So, at a 1% tolerance level, if our user sends a 
// transaction with 1 ETH and 200 DAI, amountETHMin should be set to e.g. .99 ETH, and amountTokenMin 
// should be set to 198 DAI. This means that, at worst, liquidity will be added at a rate between 
// 198 DAI/1 ETH and 202.02 DAI/1 ETH (200 DAI/.99 ETH).
//
// Once the price calculations have been made, it’s important to ensure that your contract 
//      a) controls at least as many tokens/ETH as were passed as amount*Desired parameters, and 
//      b) has granted approval to the router to withdraw this many tokens.
//

interface IUniswapV2Router01 {
    
    /// Returns factory address
    function factory() external pure returns (address);

    /// Returns the canonical WETH address on the Ethereum mainnet, or the Ropsten, Rinkeby, Görli, or 
    /// Kovan testnets.
    function WETH() external pure returns (address);

    /// Adds liquidity to an ERC-20⇄ERC-20 pool.
    /// 
    /// To cover all possible scenarios, msg.sender should have already given the router an allowance of 
    /// at least amountADesired/amountBDesired on tokenA/tokenB.
    /// Always adds assets at the ideal ratio, according to the price when the transaction is executed.
    /// If a pool for the passed tokens does not exists, one is created automatically, and exactly 
    /// amountADesired/amountBDesired tokens are added.
    ///
    /// Name            Type	
    /// tokenA	        address	    The contract address of the desired token.
    /// tokenB	        address	    The contract address of the desired token.
    /// amountADesired	uint	    The amount of tokenA to add as liquidity if the B/A price 
    ///                             is <= amountBDesired/amountADesired (A depreciates).
    /// amountBDesired	uint	    The amount of tokenB to add as liquidity if the A/B price 
    ///                             is <= amountADesired/amountBDesired (B depreciates).
    /// amountAMin	    uint	    Bounds the extent to which the B/A price can go up before the 
    ///                             transaction reverts. Must be <= amountADesired.
    /// amountBMin	    uint	    Bounds the extent to which the A/B price can go up before the 
    ///                             transaction reverts. Must be <= amountBDesired.
    /// to	            address	    Recipient of the liquidity tokens.
    /// deadline	    uint	    Unix timestamp after which the transaction will revert.
    /// 
    /// RETURNS
    /// amountA	        uint	    The amount of tokenA sent to the pool.
    /// amountB	        uint	    The amount of tokenB sent to the pool.
    /// liquidity	    uint	    The amount of liquidity tokens minted.
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    /// Adds liquidity to an ERC-20⇄WETH pool with ETH.
    /// 
    /// To cover all possible scenarios, 
    /// 
    /// msg.sender should have already given the router an allowance of at least amountTokenDesired 
    /// on token.
    /// 
    /// Always adds assets at the ideal ratio, according to the price when the transaction is executed.
    /// 
    /// msg.value is treated as a amountETHDesired.
    /// 
    /// Leftover ETH, if any, is returned to msg.sender.
    /// 
    /// If a pool for the passed token and WETH does not exists, one is created automatically, and exactly 
    /// amountTokenDesired/msg.value tokens are added.
    /// 
    /// Name	            Type	
    /// token	            address	    The contract address of the desired token.
    /// amountTokenDesired	uint	    The amount of token to add as liquidity if the WETH/token price 
    ///                                 is <= msg.value/amountTokenDesired (token depreciates).
    /// msg.value 	        uint	    The amount of ETH to add as liquidity if the token/WETH price 
    /// (amountETHDesired)              is <= amountTokenDesired/msg.value (WETH depreciates).
    /// amountTokenMin	    uint	    Bounds the extent to which the WETH/token price can go up before 
    ///                                 the transaction reverts. Must be <= amountTokenDesired.
    /// amountETHMin	    uint	    Bounds the extent to which the token/WETH price can go up before 
    ///                                 the transaction reverts. Must be <= msg.value.
    /// to	                address	    Recipient of the liquidity tokens.
    /// deadline	        uint	    Unix timestamp after which the transaction will revert.
    /// 
    /// RETURNS
    /// amountToken	        uint	    The amount of token sent to the pool.
    /// amountETH	        uint	    The amount of ETH converted to WETH and sent to the pool.
    /// liquidity	        uint	    The amount of liquidity tokens minted.
    function addLiquidityETH(
        address token,              
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    
    /// Removes liquidity from an ERC-20⇄ERC-20 pool.
    ///
    /// msg.sender should have already given the router an allowance of at least liquidity on the pool.
    /// 
    /// Name	    Type	
    /// tokenA	    address	    The contract address of the desired token.
    /// tokenB	    address	    The contract address of the desired token.
    /// liquidity	uint	    The amount of liquidity tokens to remove.
    /// amountAMin	uint	    The minimum amount of tokenA that must be received for the transaction 
    ///                         not to revert.
    /// amountBMin	uint	    The minimum amount of tokenB that must be received for the transaction 
    ///                         not to revert.
    /// to	        address	    Recipient of the underlying assets.
    /// deadline	uint	    Unix timestamp after which the transaction will revert.
    /// 
    /// RETURNS
    /// amountA	    uint	    The amount of tokenA received.
    /// amountB	    uint	    The amount of tokenB received.
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    /// Removes liquidity from an ERC-20⇄WETH pool and receive ETH.
    /// 
    ///  msg.sender should have already given the router an allowance of at least liquidity on the pool.
    /// 
    /// Name	        Type	
    /// token	        address	    The contract address of the desired token.
    /// liquidity	    uint	    The amount of liquidity tokens to remove.
    /// amountTokenMin	uint	    The minimum amount of token that must be received for the transaction 
    ///                             not to revert.
    /// amountETHMin	uint	    The minimum amount of ETH that must be received for the transaction 
    ///                             not to revert.
    /// to	            address	    Recipient of the underlying assets.
    /// deadline	    uint	    Unix timestamp after which the transaction will revert.
    /// 
    /// RETURNS
    /// amountToken	    uint	    The amount of token received.
    /// amountETH	    uint	    The amount of ETH received.
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    /// Removes liquidity from an ERC-20⇄ERC-20 pool without pre-approval, thanks to permit.
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    
    /// Removes liquidity from an ERC-20⇄WETTH pool and receive ETH without pre-approval, thanks to 
    /// permit.
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    
    /// Swaps an exact amount of input tokens for as many output tokens as possible, along the route 
    /// determined by the path. The first element of path is the input token, the last is the output 
    /// token, and any intermediate elements represent intermediate pairs to trade through (if, for 
    /// example, a direct pair does not exist).
    /// 
    /// msg.sender should have already given the router an allowance of at least amountIn on the input 
    /// token.
    /// 
    /// Name	        Type	
    /// amountIn	    uint	            The amount of input tokens to send.
    /// amountOutMin	uint	            The minimum amount of output tokens that must be received for 
    ///                                     the transaction not to revert.
    /// path	        address[] calldata	An array of token addresses. path.length must be >= 2. Pools 
    ///                                     for each consecutive pair of addresses must exist and have 
    ///                                     liquidity.
    /// to	            address	            Recipient of the output tokens.
    /// deadline	    uint	            Unix timestamp after which the transaction will revert.
    /// 
    /// RETURNS
    /// amounts	        uint[] memory	    The input token amount and all subsequent output token amounts.
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    
    /// Receive an exact amount of output tokens for as few input tokens as possible, along the route 
    /// determined by the path. The first element of path is the input token, the last is the output 
    /// token, and any intermediate elements represent intermediate tokens to trade through (if, for 
    /// example, a direct pair does not exist).
    /// 
    /// msg.sender should have already given the router an allowance of at least amountInMax on the input 
    /// token.
    /// 
    /// Name	        Type	
    /// amountOut	    uint	            The amount of output tokens to receive.
    /// amountInMax	    uint	            The maximum amount of input tokens that can be required before 
    ///                                     the transaction reverts.
    /// path	        address[] calldata	An array of token addresses. path.length must be >= 2. Pools 
    ///                                     for each consecutive pair of addresses must exist and have 
    ///                                     liquidity.
    /// to	            address	            Recipient of the output tokens.
    /// deadline	    uint	            Unix timestamp after which the transaction will revert.
    /// 
    /// RETURNS
    /// amounts	        uint[] memory	    The input token amount and all subsequent output token amounts.
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    
    /// Swaps an exact amount of ETH for as many output tokens as possible, along the route determined 
    /// by the path. The first element of path must be WETH, the last is the output token, and any 
    /// intermediate elements represent intermediate pairs to trade through (if, for example, a direct 
    /// pair does not exist).
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    
    /// Receive an exact amount of ETH for as few input tokens as possible, along the route determined 
    /// by the path. The first element of path is the input token, the last must be WETH, and any 
    /// intermediate elements represent intermediate pairs to trade through (if, for example, a direct 
    /// pair does not exist).
    /// 
    /// msg.sender should have already given the router an allowance of at least amountInMax on the input 
    /// token.
    /// 
    /// If the to address is a smart contract, it must have the ability to receive ETH.
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    
    /// Swaps an exact amount of tokens for as much ETH as possible, along the route determined by the 
    /// path. The first element of path is the input token, the last must be WETH, and any intermediate 
    /// elements represent intermediate pairs to trade through (if, for example, a direct pair does not 
    /// exist).
    /// 
    /// If the to address is a smart contract, it must have the ability to receive ETH.
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    
    /// Receive an exact amount of tokens for as little ETH as possible, along the route determined by 
    /// the path. The first element of path must be WETH, the last is the output token and any 
    /// intermediate elements represent intermediate pairs to trade through (if, for example, a direct 
    /// pair does not exist).
    /// 
    /// Leftover ETH, if any, is returned to msg.sender.
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    /// Given some asset amount and reserves, returns an amount of the other asset representing equivalent 
    /// value. Useful for calculating optimal token amounts before calling mint.
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    /// Given an input asset amount, returns the maximum output amount of the other asset (accounting for 
    /// fees) given reserves.
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    /// Returns the minimum input asset amount required to buy the given output asset amount (accounting 
    /// for fees) given reserves.
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    
    /// Given an input asset amount and an array of token addresses, calculates all subsequent maximum 
    /// output token amounts by calling getReserves for each pair of token addresses in the path in turn, 
    /// and using these to call getAmountOut.
    /// 
    /// Useful for calculating optimal token amounts before calling swap.
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    
    /// Given an output asset amount and an array of token addresses, calculates all preceding minimum 
    /// input token amounts by calling getReserves for each pair of token addresses in the path in turn, 
    /// and using these to call getAmountIn.
    ///
    /// Useful for calculating optimal token amounts before calling swap.
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
