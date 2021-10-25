//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;

import "./Uniswap/IUniswapV2Factory.sol";
import "./Uniswap/IUniswapV2Router02.sol";
import "./OpenZeppelin/ERC20.sol";
import "./OpenZeppelin/Address.sol";

import "./OwnableExt.sol";
import "./Math/Math.sol";
import "./Utils.sol";
import "./ChainLinkPriceFeedLib.sol";
import "./ChainlinkFeed.sol";
import "./Stakes.sol";

// Google Spreadsheet for gas cost calculation
// https://docs.google.com/spreadsheets/d/1n6mRqkBz3iWcOlRem_mO09GtSKEKrAsfO7Frgx18pNU/edit?usp=sharing

// block.coinbase (address payable)	                Current block miner’s address
// block.difficulty (uint)	                        Current block difficulty
// msg.value (uint)	                                Number of wei sent with the message
// block.number (uint):                             Current block number
// blockhash(uint blockNumber) returns (bytes32)	Gives hash of the given block and will only work 
//                                                  for the 256 most recent block due to the reason of 
//                                                  scalability.
// block.timestamp: 	                            Current block timestamp as seconds since unix epoch
// gasleft() returns (uint256):	                    Remaining gas
// msg.sender (address payable)	                    Sender of the message (current call)
// msg.sig (bytes4)	                                First four bytes of the calldata (i.e. function identifier)
// now (uint)	                                    Current block timestamp (alias for block.timestamp)
// tx.gasprice (uint)	                            Gas price of the transaction
// block.gaslimit (uint)	                        Current block gaslimit
// tx.origin (address payable)	                    Sender of the transaction (full call chain)
// msg.data (bytes calldata)	                    Complete calldata

/*
    https://blog.soliditylang.org/2021/04/21/custom-errors/

    Starting from Solidity v0.8.4, there is a convenient and gas-efficient way to explain to users why 
    an operation failed through the use of custom errors. Until now, you could already use strings to 
    give more information about failures (e.g., revert("Insufficient funds.");), but they are rather 
    expensive, especially when it comes to deploy cost, and it is difficult to use dynamic information 
    in them.

    Custom errors are defined using the error statement, which can be used inside and outside of 
    contracts (including interfaces and libraries).

    /// @param available balance available.
    /// @param required requested amount to transfer.
    error InvalidZeroAddress();
    error InsufficientAllowance(uint256 available, uint256 required);

    Linter, ether.js and web3.js still don't support error
*/

contract Dolly is OwnableExt, ERC20, ChainlinkFeed, Stakes {

    /*
        Each account has a data area called storage, which is persistent between function calls and 
        transactions. Storage is a key-value store that maps 256-bit words to 256-bit words. It is not 
        possible to enumerate storage from within a contract, it is comparatively costly to read, and 
        even more to initialise and modify storage. Because of this cost, you should minimize what you 
        store in persistent storage to what the contract needs to run. Store data like derived 
        calculations, caching, and aggregates outside of the contract. A contract can neither read nor 
        write to any storage apart from its own.

        State variables of contracts are stored in storage in a compact way such that multiple values 
        sometimes use the same storage slot. Except for dynamically-sized arrays and mappings (see below), 
        data is stored contiguously item after item starting with the first state variable, which is 
        stored in slot 0. For each variable, a size in bytes is determined according to its type. 
        Multiple, contiguous items that need less than 32 bytes are packed into a single storage slot 
        if possible, according to the following rules:

        1)  The first item in a storage slot is stored lower-order aligned.
        2)  Value types use only as many bytes as are necessary to store them.
        3)  If a value type does not fit the remaining part of a storage slot, it is stored in the next 
            storage slot.
        4)  Structs and array data always start a new slot and their items are packed tightly according 
            to these rules.
        5)  Items following struct or array data always start a new storage slot.

        For contracts that use inheritance, the ordering of state variables is determined by the 
        C3-linearized order of contracts starting with the most base-ward contract. If allowed by the 
        above rules, state variables from different contracts do share the same storage slot.

        The elements of structs and arrays are stored after each other, just as if they were given as 
        individual values.

        When using elements that are smaller than 32 bytes, your contract’s gas usage may be higher. 
        This is because the EVM operates on 32 bytes at a time. Therefore, if the element is smaller 
        than that, the EVM must use more operations in order to reduce the size of the element from 
        32 bytes to the desired size.

        The layout of state variables in storage is considered to be part of the external interface of 
        Solidity due to the fact that storage pointers can be passed to libraries. This means that any 
        change to the rules outlined is considered a breaking change of the language and due to its 
        critical nature should be considered very carefully before being executed.

        The data set location is important not only for the persistence of data but also for semantics 
        of assignment. Let’s look at each behavior;

        https://medium.com/coinmonks/solidity-fundamentals-a71bf54c0b98
        
        Assignments between storage and memory (or from calldata) always create an independent copy.
        Assignments from memory to memory only create references. As a result changes to one memory 
                    variable are also visible in all other memory variables that refer to the same data.
        Assignments from storage to a localstorage variable also only assign a reference.
        All other assignments to storage always creates independent copies.        
    */

    /*
        assert(false) compiles to 0xfe, which is an invalid opcode, using up all remaining gas, and 
        reverting all changes.

        require(false) compiles to 0xfd which is the REVERT opcode, meaning it will refund the 
        remaining gas. The opcode can also return a value (useful for debugging), but I don't believe that 
        is supported in Solidity as of this moment. (2017-11-21)
    */

    // State variables can be declared as public, private, or internal but not external.
    // Unlike functions, state variables cannot be overridden by re-declaring it in the child contract.
    // Inherited state variables can be then reassigned in the child object's constructor

    uint256 private _totalTokens = 500000000; //issued 500 millions tokens
    uint256 private _adminSupply = 0; //admin supply in token wei (_totalSupply * x% * 10 ** decimals)
    uint256 private _salesSupply = 0; //sales supply in token wei (_totalSupply * x% * 10 ** decimals)

    uint256 private _deployedChainId = 0;

    // Uniswap router address and Pair
    IUniswapV2Router02 public immutable UniswapV2Router02;
    address public immutable UniswapV2Pair;

    event EtherReceived(uint256 _ethers, uint256 tokens, uint8 origin);
    event FundTransfer(address _recipient, uint256 _amount, bool _isContribution);

    /**
     * Initializes the contract setting the total supply     
     * Constructor code is only run when the contract is created
     */
    constructor(uint8 _chainId, address _chainLinkFeed, address _uniswapV2Router02) 
            ERC20("Dolly", "DOL") ChainlinkFeed(_chainLinkFeed) {

        // create Uniswap router
        IUniswapV2Router02 _uniV2Router02 = IUniswapV2Router02(_uniswapV2Router02);

        // Create a uniswap pair for this new token
        UniswapV2Pair = IUniswapV2Factory(_uniV2Router02.factory())
                              .createPair(address(this), _uniV2Router02.WETH());

        // assign immutable router
        UniswapV2Router02 = _uniV2Router02;

        // keep track of deployed blockchain
        _deployedChainId = _chainId;

        //exclude owner and this contract from fee
        super.excludeFromFee(owner());
        super.excludeFromFee(address(this));
        
        // https://docs.openzeppelin.com/contracts/2.x/erc20-supply
        _mint(owner(), _totalTokens * ONE_TOKEN());

    }

    /**
     * Throws if the funds into the account are insufficient.
     */
    modifier hasSufficientFunds(address account, uint256 amount) {
        require(super.balanceOf(account) >= amount, "ERC20: transfer amount exceeds account balance");
        _;
    }

    /******************************************************************
    *                     PRIVATE FUNCTIONS
    *
    * private- only inside the contract that defines the function
    *
    * Private function can only be called
    * - inside this contract
    * Contracts that inherit this contract CANNOT call this function.
    *******************************************************************/

    /**
     * Returns the correct representation of one token as uint256 accordingly to decimals.
     * 1 token is 1000000000000000000 (a 1 with 18 zeros after it)
     * 1,000,000 tokens, set _initialSupply to a 1 with 24 zeros after it (18 + 6).
     */
    function ONE_TOKEN() private pure returns (uint256) {
        return(10 ** uint256(decimals()));
    }

    /*************************************************************
    *                     UNISWAP FUNCTIONS
    **************************************************************/

    // https://jeiwan.medium.com/programming-defi-uniswap-part-1-839ebe796c7b

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UniswapV2Router02.WETH();

        // msg.sender should have already given the router an allowance of at least amountIn on the 
        // input token.
        _approve(address(this), address(UniswapV2Router02), tokenAmount);

        // make the swap
        UniswapV2Router02.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    // https://jeiwan.medium.com/programming-defi-uniswap-part-1-839ebe796c7b

    // Adds liquidity to an ERC-20⇄WETH pool with ETH.
    //
    // To cover all possible scenarios, msg.sender should have already given the router an allowance 
    // of at least amountTokenDesired on token.
    // 
    // Always adds assets at the ideal ratio, according to the price when the transaction is executed.
    // 
    // msg.value is treated as a amountETHDesired.
    //
    // Leftover ETH, if any, is returned to msg.sender.
    // 
    // If a pool for the passed token and WETH does not exists, one is created automatically, and 
    // exactly amountTokenDesired/msg.value tokens are added.
    //
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        // approve token transfer to cover all possible scenarios
        // msg.sender should have already given the router an allowance of at least 
        // amountADesired/amountBDesired on tokenA/tokenB.
        _approve(address(this), address(UniswapV2Router02), tokenAmount);

        // add liquidity with WETH involved
        UniswapV2Router02.addLiquidityETH{ value: ethAmount } (
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );

    }

    /******************************************************************
    *                     INTERNAL FUNCTIONS
    *
    * internal- only inside contract that inherits an internal function
    *
    * Internal function can be called
    * - inside this contract
    * - inside contracts that inherit this contract
    *******************************************************************/

    /** 
     * reserve an amount of tokens for pre-sales account. Token are not transferred, but approved
     *
     * Requirements:
     *
     *   current sales address must be valid and cannot be the zero address, contract address, 
     *   owner address, or admin address
     *
     *   number of tokens cannot exceeds the owner balance
     */
    function _updateSalesTokens(uint256 tokens) internal {
        uint256 _supply = tokens  * ONE_TOKEN();
        require(_supply < super.balanceOf(owner()), "ERC20: pre-sales amount exceeds owner balance");
        _salesSupply = _supply;
        _approve(owner(), sales(), _salesSupply); //approved for crowd sale, tokens are not moved
    }

    /** 
     * reserve an amount of tokens for admin account. Tokens are moved from owner to admin account
     *
     * Requirements:
     *
     *   current sales address must be valid and cannot be the zero address, contract address, 
     *   owner address, or admin address
     *
     *   number of tokens cannot exceeds the owner balance
     */
    function _updateAdminTokens(uint256 tokens) internal {
        require(tokens < super.totalSupply(), "ERC20: admin tokens cannot exceed total supply");
        uint256 _newSupply = tokens * ONE_TOKEN();
        uint256 _balance = super.balanceOf(admin());
        require(_newSupply != _balance, "ERC20: there is nothing to update for admin tokens");
        if (_newSupply > _balance) {
            super._transfer(owner(), admin(), _newSupply - _balance); 
        } else {
            super._transfer(admin(), owner(), _balance - _newSupply); 
        }
        _adminSupply = _newSupply;
    }

    /*
        The contract will receive ethers in exchange of tokens
    */
    function _buyTokens(IERC20 token, uint256 ethersSent, uint8 origin) internal {
        // maximum number of tokens could be obtained
        uint256 balance = token.balanceOf(owner());
        // calculate how many tokens in exchange for ethers sent
        uint256 tokens = _calculateTokensFromETH(balance, ethersSent);
        // transfer of tokens in exchange of ethers
        _transfer(owner(), _msgSender(), tokens); 
        // emit notification
        emit EtherReceived(ethersSent, tokens, origin);
    }

    /*************************************************************
    *                     PUBLIC FUNCTIONS
    *
    * public - any contract and account can call
    *
    * Public functions can be called
    * - inside this contract
    * - inside contracts that inherit this contract
    * - by other contracts and accounts
    **************************************************************/

    /**
     * Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     */
    function decimals() public pure override returns (uint8) { // override to make it pure
         return 18;
    }

    /**
     * Returns the amount of tokens owned by `account`, without decimals.
     */
    function balanceTokensOf(address account) public view returns (uint256) {
        return super.balanceOf(account) / ONE_TOKEN();
    }

    /**
     * Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     *
     * Checking transfer function is very important, because there may be issues that would cause 
     * incorrect transfers. You must make sure that recipient’s and sender’s balances will change upon 
     * transfer, try to get reverts in case function gets wrong parameters, for example, when amount 
     * being sent exceeds the sender’s balance, when contract address or invalid address is sent instead 
     * of recipient address, etc. And finally you must check that you get correct logs from transfer event
     */
    function transfer(address recipient, uint256 amount) public  nonReentrant whenNotPaused override returns (bool) {
        _transfer(_msgSender(), recipient, amount); // override to let pause the transfers
        return true;
    }

    /**
     * Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     *
     * transferFrom function is very similar to transfer, but here you also need to test that spender has 
     * enough approved balance for sending. Here are tests when spender has less amount of funds than 
     * required for transfer.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public nonReentrant whenNotPaused 
                override returns (bool) {
        uint256 currentAllowance = super.allowance(sender, _msgSender());
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _transfer(sender, recipient, amount);
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        return true;
    }

    /**
     * Destroys `amount` tokens from the caller.
     */
    function burn(uint256 amount) public nonReentrant whenNotPaused {
        _burn(_msgSender(), amount);
    }

    /**
     * Destroys `amount` tokens from `account`, deducting from the caller's allowance.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least `amount`.
     */
    function burnFrom(address account, uint256 amount) public nonReentrant whenNotPaused {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);
    }

    /** 
     * Creates `amount` tokens and assigns them to `account`, increasing the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function mint(address account, uint256 amount) public nonReentrant onlyOwnerOrAdmin whenNotPaused {
        _mint(account, amount);
    }

    /*
        Query ChainLink network for last ETH/USD price
    */
    function ETHUSDPrice() public view onlyOwnerOrAdmin returns (uint256, uint8) {
        return ChainLinkPriceFeedLib.readPrice(chainLinkPriceFeedETHUSD);
    }

    /**
     *  Generate a pseudo random number
     */
    // function predictableRandomNumber(uint256 limit, uint256 nonce) public view returns (uint256) {
    //     return Math.randomNumber(limit, nonce);
    // }

    /**
     *  Pause the contract
     */
    function pause() external onlyOwnerOrAdmin whenNotPaused {
        _pause();
    }

    /*************************************************************
    *                     EXTERNAL FUNCTIONS
    *
    * external - only other contracts and accounts can call
    *
    * External functions can only be called
    * - by other contracts and accounts
    **************************************************************/

    // function updateRouterAddress(address newRouter) public onlyOwnerOrAdmin {
    //     IUniswapV2Router02 _newRouter = IUniswapV2Router02(newRouter);
    //     UniswapV2Pair = IUniswapV2Factory(_newRouter.factory()).createPair(address(this), 
    //                                         _newRouter.WETH());
    //     UniswapV2Router02 = _newRouter;
    // }

    /** 
     * reserve an amount of tokens for sales() account and update that address.
     *
     * Requirements:
     *
     * - account cannot be the zero address, contract address, owener address,
     *   admin address and current sales address
     */
    function updateSalesAddress(address account) external onlyOwnerOrAdmin 
                                    isnotZeroConOwnAdmSales(account) returns (bool) {
        if (_salesSupply > 0) {
            decreaseAllowance(sales(), _salesSupply); //remove current allowance
            approve(account, _salesSupply); //approved for crowd sale, tokens are not moved
        }
        _changeSales(account);
        return true;
    }

    /** 
     * reserve an amount of tokens for pre-sales account. Token are not transferred, but approved
     *
     * Requirements:
     *
     *   current sales address must be valid and cannot be the zero address, contract address, 
     *   owner address, or admin address
     *
     *   number of tokens cannot exceeds the owner balance
     */
    function updateSalesTokens(uint256 tokens) external onlyOwnerOrAdmin 
                        isnotZeroConOwnAdm(sales()) returns (bool) {
        _updateSalesTokens(tokens);
        return true;
    }

    /**
     * The current admin of the contract can assign a new admin
     */
    function updateAdminAddress(address _newAdmin) external onlyOwner 
                                    isnotZeroConOwnAdm(_newAdmin) returns (bool) {
        if (_adminSupply > 0) {
            _transfer(admin(), _newAdmin, super.balanceOf(admin())); //transfer the balance to new admin
        }
        _changeAdmin(_newAdmin);
        return true;
    }

    /** 
     * reserve an amount of tokens for admin account.
     */
    function updateAdminTokens(uint256 tokens) external onlyOwnerOrAdmin 
               isnotZeroConOwn(admin()) returns (bool) {
        _updateAdminTokens(tokens);
        return true;
    }

    /**
     * The owner can call this function to withdraw the funds that
     * have been sent to this contract.
     */
    function withdrawal() external onlyOwner {
        uint balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
        emit FundTransfer(owner(), balance, false);
    }

    /*
        Remove the contract from blockchain and send all ethers to owner address
    */
    function killContract () external onlyOwner {
        // This method will not trigger fallback function
        selfdestruct (payable(owner()));
    }

    /*
        The contract will receive ethers in exchange of tokens
    */
    function buyTokens() public payable {
        _buyTokens(this, msg.value, 0); //explicit buy
    }

    /** 
    The contract will receive ethers.

    receive() external payable — for empty calldata (and any value)

    The receive function is executed on a call to the contract with empty calldata. This is the 
    function that is executed on plain Ether transfers (e.g. via .send() or .transfer()). 
    If no such function exists, but a payable fallback function exists, the fallback function 
    will be called on a plain Ether transfer. If neither a receive Ether nor a payable fallback 
    function is present, the contract cannot receive Ether through regular transactions and throws 
    an exception.
     
    In the worst case, the receive function can only rely on 2300 gas being available (for example 
    when send or transfer is used), leaving little room to perform other operations except basic 
    logging. The following operations will consume more gas than the 2300 gas stipend:
     
    Writing to storage
    Creating a contract
    Calling an external function which consumes a large amount of gas
    Sending Ether
     
    Contracts that receive Ether directly (without a function call, i.e. using send or transfer) 
    but do not define a receive Ether function or a payable fallback function throw an exception, 
    sending back the Ether (this was different before Solidity v0.4.0). So if you want your contract 
    to receive Ether, you have to implement a receive Ether function (using payable fallback 
    functions for receiving Ether is not recommended, since it would not fail on interface confusions).
     
    A contract without a receive Ether function can receive Ether as a recipient of a coinbase 
    transaction (aka miner block reward) or as a destination of a selfdestruct.
    A contract cannot react to such Ether transfers and thus also cannot reject them. This is a 
    design choice of the EVM and Solidity cannot work around it.
      
    It also means that address(this).balance can be higher than the sum of some manual accounting 
    implemented in a contract (i.e. having a counter updated in the receive Ether function).

    Solidity 0.6.x introduced the receive keyword in order to make contracts more explicit when their 
    fallback functions are called. The receive method is used as a fallback function in a contract and 
    is called when ether is sent to a contract with no calldata. If the receive method does not exist, 
    it will use the fallback function. 

    There are two ways of interacting with a contract. A call (read-only, doesn't change the state, and 
    therefore doesn't require a transaction, and is free), and a transaction which does change the state.

    When you 'transact' a function on a contract, you're really just sending an ordinary transaction to 
    that contract, with some data. You could do this "by hand" with sendTransaction: just add a data 
    field. That data tells the contract which of its functions you want to call (via the signature, 
    which serves as a function selector), and which arguments to pass it.

    A receive or fallback function is there to deal with cases where a transaction is sent to the 
    contract but the function selector doesn't correspond to the signature of any function on the 
    contract, including the case when no data is provided. A good example is the fallback function of 
    the wrapped ether (WETH) contract, whereby if the contract receives a transaction with no data, the 
    fallback function automatically calls the 'deposit' function.

    So, if you want to trigger a fallback or receive function, just send some ether (or a 0 ether 
    transaction) to that contract.

    Which function is called, fallback() or receive()?

                   send Ether
                       |
                msg.data is empty?
                      / \
                    yes  no
                    /     \
        receive() exists?  fallback()
                /   \
               yes   no
               /      \
        receive()   fallback()

     */
    receive () external payable {
        _buyTokens(this, msg.value, 1); //buy no calldata
    }

    /** 
    
    The contract will receive ethers in exchange of tokens.
    
    fallback is a function that does not take any arguments and does not return anything.

    It is executed either when
        - a function that does not exist is called or
        - Ether is sent directly to a contract but receive() does not exist or msg.data is not empty

    fallback() external payable — when no other function matches (not even the receive function). 
    Optionally payable. (like when you send ETH without specifically calling any function).

    The fallback function is executed on a call to the contract if none of the other functions 
    match the given function signature, or if no data was supplied at all and there is no receive 
    Ether function. The fallback function always receives data, but in order to also receive Ether 
    it must be marked payable.
    
    A payable fallback function is also executed for plain Ether transfers, if no receive Ether 
    function is present. It is recommended to always define a receive Ether function as well, if 
    you define a payable fallback function to distinguish Ether transfers from interface confusions.

    Which function is called, fallback() or receive()?

                   send Ether
                       |
                msg.data is empty?
                      / \
                    yes  no
                    /     \
        receive() exists?  fallback()
                /   \
               yes   no
               /      \
        receive()   fallback()

    */
    fallback () payable external {
        _buyTokens(this, msg.value, 2); //buy no matching function
    }

    // https://2π.com/17/basic-contracts/
    // We can use these functions to send the tokens to owner on terminate
    function terminate(IERC20[] memory tokens) external onlyOwner {
        // Transfer tokens to owner
        for(uint i = 0; i < tokens.length; i++) {
            uint256 balance = tokens[i].balanceOf(address(this));
            tokens[i].transfer(owner(), balance);
        }
        // Transfer Ether to owner and terminate contract
        selfdestruct(payable(owner()));
    }
}
