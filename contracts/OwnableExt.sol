//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;

import "./OpenZeppelin/Ownable.sol";
import "./OpenZeppelin/Pausable.sol";
import "./OpenZeppelin/ReentrancyGuard.sol";

/**
 * Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.

 Block and Transaction Properties

    block.blockhash(uint blockNumber) returns (bytes32): hash of the given block - only works for 256 most recent blocks excluding current
    block.coinbase (address): current block miner’s address
    block.difficulty (uint): current block difficulty
    block.gaslimit (uint): current block gaslimit
    block.number (uint): current block number
    block.timestamp (uint): current block timestamp as seconds since unix epoch
    gasleft() returns (uint256): remaining gas
    msg.data (bytes): complete calldata
    msg.sender (address): sender of the message (current call)
    msg.sig (bytes4): first four bytes of the calldata (i.e. function identifier)
    msg.value (uint): number of wei sent with the message
    now (uint): current block timestamp (alias for block.timestamp)
    tx.gasprice (uint): gas price of the transaction
    tx.origin (address): sender of the transaction (full call chain)

Address Related

<address>.balance (uint256):
    balance of the Address in Wei
<address>.transfer(uint256 amount):
    send given amount of Wei to Address, throws on failure, forwards 2300 gas stipend, not adjustable
<address>.send(uint256 amount) returns (bool):
    send given amount of Wei to Address, returns false on failure, forwards 2300 gas stipend, not adjustable
<address>.call(...) returns (bool):
    issue low-level CALL, returns false on failure, forwards all available gas, adjustable
<address>.callcode(...) returns (bool):
    issue low-level CALLCODE, returns false on failure, forwards all available gas, adjustable
<address>.delegatecall(...) returns (bool):
    issue low-level DELEGATECALL, returns false on failure, forwards all available gas, adjustable

For more information, see the section on Address.
There are some dangers in using send: The transfer fails if the call stack depth is at 1024 (this can 
always be forced by the caller) and it also fails if the recipient runs out of gas. So in order to make 
safe Ether transfers, always check the return value of send, use transfer or even better: Use a pattern 
where the recipient withdraws the money.
 */
abstract contract OwnableExt is Ownable, Pausable, ReentrancyGuard {

    address private _admin; // administrator or the contract
    address private _sales; //crowd sale admin address

    //address payable _withdraw; //withdraw address for ethers

    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    event AdminChanged(address account); //fired when the admin has been changed
    event SalesChanged(address account); //fired when the admin has been changed

    /**
     * Initializes the contract setting the deployer as the initial owner     
     * Constructor code is only run when the contract is created
     */
    constructor () Ownable() {

        _admin = address(0); //admin account for reserved tokens
        _sales = address(0); //sales address for crowd sales

        emit OwnershipTransferred(address(0), owner());

    }

    /*************************************************************
    *                       MODIFIERS
    **************************************************************/

    /**
     * Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        require(_admin == msg.sender, "ERC20: function call reserved to contract admin");
        _;
    }

    /**
     * Throws if called by any account other than the owner or admin.
     */
    modifier onlyOwnerOrAdmin() {
        require(owner() == msg.sender || 
                _admin == msg.sender, "ERC20: function call reserved to contract admin");
        _;
    }

    /**
     * Throws if called by any account other than the owner or admin.
     */
    modifier onlyOwnerAdminsOrSales() {
        require(owner() == msg.sender || 
                _admin == msg.sender  || 
                _sales == msg.sender, 
                "ERC20: function call reserved to contract admins or sales agents");
        _;
    }

    /**
     * Throws if the address is a zero address.
     */
    modifier isnotZero(address account) {
        require(account != address(0), "ERC20: must not be zero address");
        _;
    }

    /**
     * Throws if the address is a zero address or contract address.
     */
    modifier isnotZeroCon(address account) {
        require(account != address(0), "ERC20: must not be zero address");
        require(account != address(this), "ERC20: must not be the token address");
        _;
    }

    /**
     * Throws if zero, contract or owner address.
     */
    modifier isnotZeroConOwn(address account) {
        require(account != address(0), "ERC20: must not be zero address");
        require(account != address(this), "ERC20: must not be the token address");
        require(account != owner(), "ERC20: must not be the owner's address");
        _;
    }

    /**
     * Throws if zero, contract, owner or admin address.
     */
    modifier isnotZeroConOwnAdm(address account) {
        require(account != address(0), "ERC20: must not be zero address");
        require(account != address(this), "ERC20: must not be the token address");
        require(account != owner(), "ERC20: must not be the owner's address");
        require(account != address(_admin), "ERC20: must not be the admin's address"); //
        _;
    }

    /**
     * Throws if zero, contract, owner, admin or sales address.
     */
    modifier isnotZeroConOwnAdmSales(address account) {
        require(account != address(0), "ERC20: must not be zero address");
        require(account != address(this), "ERC20: must not be the token address");
        require(account != owner(), "ERC20: must not be the owner's address");
        require(account != address(_admin), "ERC20: must not be the admin's address"); //
        require(account != address(_sales), "ERC20: must not be the token offering contract address");
        _;
    }

    function _changeAdmin(address _newAdmin) internal {
        _admin = _newAdmin;
        emit AdminChanged(_newAdmin);
    }

    function _changeSales(address _newSales) internal {
        _sales = _newSales; //new sales address
        emit SalesChanged(_newSales);
    }

    /*************************************************************
    *                     PUBLIC FUNCTIONS
    **************************************************************/

    /**
     * Returns the address of the current admin.
     */
    function admin() public view returns (address) {
        return _admin;
    }

    /**
     * Returns the address of the current admin.
     */
    function sales() public view returns (address) {
        return _sales;
    }

}