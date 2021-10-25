//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;

import "./OpenZeppelin/IERC20.sol";
import "./ChainLink/AggregatorV3Interface.sol";
import "./ChainLinkPriceFeedLib.sol";
import "./OwnableExt.sol";
import "./Utils.sol";

contract ChainlinkFeed is OwnableExt {

    struct Transaction {
        uint256 ethers;
        uint256 tokens;
    }

    // Keeps track of the total amount of tokens sent to the contract by an address
    // _tokens_sent[tokenaddress][useraddress] = quantity
    mapping (address => mapping(address => Transaction)) internal _tokens_sent;

    struct ExchData {
        bool active;
        bool dynamic;
        uint256 exchangeRateUSD;    // DOLLY vs USD (how many DOLLY per 1 USD) DYNAMIC ETHER PRICE IN USD
        uint256 exchangeRateETH;    // DOLLY vs Ether (how many DOLLY per 1 Ether) FIXED EXCHANGE
    }

    // Chainlink aggregator interface address for ETH/USD
    AggregatorV3Interface internal chainLinkPriceFeedETHUSD;

    // active = true    dynamic = false     3 dolly = 1 USD     10000 Dolly = 1 ether
    ExchData internal _exchangeData = ExchData(true, false, 3, 10000);

    event ExchangeActiveChanged(bool indexed previousActive, bool indexed newActive);
    event ExchangeDynamicChanged(bool indexed previousDynamic, bool indexed newDynamic);
    event ExchangeRateETHChanged(uint256 indexed previousRate, uint256 indexed newRate);
    event ExchangeRateUSDChanged(uint256 indexed previousRate, uint256 indexed newRate);
    event ExchangeBoughtTokensByUSD(uint256 indexed ethers, uint256 indexed usd, uint256 tokens);

    constructor(address _chainLinkFeed) {

        // Make sure you have LINK coins in your wallet that you are making the request from. If you 
        // don't have LINK, you can visit Uniswap.io or Kyberswap to convert Ether to LINK. You will 
        // need .1 LINK per request.
        chainLinkPriceFeedETHUSD = AggregatorV3Interface(_chainLinkFeed);
    }

    /** 
     * return the current exchange rate of tokens vs ethers.
     */
    function currentExchangeRateinETH() external view returns (uint256) {
        return _exchangeData.exchangeRateETH;
    }

    /** 
     * return the current exchange rate of tokens vs dollars.
     */
    function currentExchangeRateinUSD() external view returns (uint256) {
        return _exchangeData.exchangeRateUSD;
    }

    /** 
     * return the current exchange status (active/blocked).
     */
    function currentExchangeIsActive() external view returns (bool) {
        return _exchangeData.active;
    }

    /** 
     * return the current exchange conversion type (static/dynamic).
     */
    function currentExchangeIsDynamic() external view returns (bool) {
        return _exchangeData.dynamic;
    }

    /** 
     * update the address of ChainLink Price Feed aggregator
     */
    function exchangeSetChainLinkAddress(address chainLinkAggregator) external 
            onlyOwnerOrAdmin isnotZeroConOwnAdmSales(chainLinkAggregator) {
        chainLinkPriceFeedETHUSD = AggregatorV3Interface(chainLinkAggregator);        
    }

    /** 
     * update the status of the exchange (active/inactive)
     */
    function exchangeSetActive(bool newActive) external onlyOwnerOrAdmin returns (bool success)  {
        if (_exchangeData.active != newActive) {
            emit ExchangeActiveChanged(_exchangeData.active, newActive);
            _exchangeData.active = newActive;
            return true;
        }
        return false;
    }

    /** 
     * update the working mode of the exchange (dynamic ETH/USD value or fixed ETH rate)
     */
    function exchangeSetDynamic(bool newDynamic) external onlyOwnerOrAdmin returns (bool success)  {
        if (_exchangeData.dynamic != newDynamic) {
            emit ExchangeDynamicChanged(_exchangeData.dynamic, newDynamic);
            _exchangeData.dynamic = newDynamic;
            return true;
        }
        return false;
    }

    /** 
     * update the rate of exchange for Dolly'tokens against 1 USD (default = 3)
     */
    function exchangeSetRateUSD(uint256 newRateUSD) external onlyOwnerOrAdmin returns (bool success) {
        if (_exchangeData.exchangeRateUSD != newRateUSD) {
            emit ExchangeRateUSDChanged(_exchangeData.exchangeRateUSD, newRateUSD);
            _exchangeData.exchangeRateUSD = newRateUSD;
            return true;
        }
        return false;
    }

    /** 
     * update the rate of exchange for Dolly'tokens against 1 ether (default = 10000)
     */
    function exchangeSetRateETH(uint256 newRateETH) external onlyOwnerOrAdmin returns (bool success) {
        if (_exchangeData.exchangeRateETH != newRateETH) {
            emit ExchangeRateETHChanged(_exchangeData.exchangeRateETH, newRateETH);
            _exchangeData.exchangeRateETH = newRateETH;
            return true;
        }
        return false;
    }

    /** 
     *  amount of ethers sent by the user
     */
    function EthersSent() external view returns (uint256 ethers) {
         return _tokens_sent[Utils.ethAddress()][_msgSender()].ethers;
    }

    /*
        calculate the amounts of tokens the user will receive against some ethers
    */
    function _calculateTokensFromETH(uint256 availableLiquidity, uint256 ethersSent) internal 
                                    returns (uint256 obtainedTokens) {
        require (_exchangeData.active, "ERC20: the exchange is currently disabled");
        require(ethersSent > 0, "ERC20: You need to send some ether");
        uint256 tokens = 0;
        if (_exchangeData.dynamic) { //dynamic conversion
            require(_exchangeData.exchangeRateUSD > 0, "ERC20: a valid exchange rate must be provided");
            int price = 0;
            uint8 USDDecimals = 0;
            // call the Chainlink Oracle
            (price, USDDecimals) = ChainLinkPriceFeedLib.readPriceAndDecimals(chainLinkPriceFeedETHUSD);            
            // converto from int256 to uint256
            uint256 ETHUSDPrice = Math.toUInt(Math.fromInt(price));
            require (ETHUSDPrice > 0, "ERC20: dynamic exchange currently unavailable");
            // 1 ether sent -> converted to 3000 USD -> converted to 180000 DOLLY at 1:30
            // 1 ether sent -> converted to 1500 USD -> converted to 90000 DOLLY at 1:30
            tokens = (ethersSent * ETHUSDPrice  * _exchangeData.exchangeRateUSD) / 10 ** USDDecimals;
            emit ExchangeBoughtTokensByUSD(ethersSent, ETHUSDPrice, tokens);
        } else { //static conversion
            require(_exchangeData.exchangeRateETH > 0, "ERC20: a valid exchange rate must be provided");
            // Doesn't matter the value of ethers in dollars, the sender will receive same amount of DOLLY
            tokens = ethersSent * _exchangeData.exchangeRateETH;
        }
        require(tokens <= availableLiquidity, "ERC20: Not enough tokens in the reserve");        
        // internally store the ethers sent by the user and tokens obtained
        _tokens_sent[Utils.ethAddress()][_msgSender()] = Transaction(ethersSent, tokens);
        return tokens;
    }

}