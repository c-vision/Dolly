//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;

import "./ChainLink/AggregatorV3Interface.sol";
import "./Math/Math.sol";

library ChainLinkPriceFeedLib {

    /*
        Query ChainLink network for last price and decimals
        - convert feed price from int256 to uint256 by Math library
        - return the current price as uint256
        - return the number of decimals which must be considered
    */
    function readPriceAndDecimals(AggregatorV3Interface feed) internal view returns (int256, uint8) {
        uint80 roundID = 0; 
        int price = 0;
        uint startedAt = 0;
        uint timeStamp = 0;
        uint80 answeredInRound = 0;
        (roundID, price, startedAt, timeStamp, answeredInRound) = feed.latestRoundData();
        require(timeStamp > 0, "Round not complete");
        return (price, feed.decimals());
    }

    /*
        Query ChainLink network for last price
    */
    function readPrice(AggregatorV3Interface feed) internal view returns (uint256, uint8) {
        int price = 0;
        uint8 dec = 0;
        (price, dec) = readPriceAndDecimals(feed);
        return (Math.toUInt(Math.fromInt(price)), dec);
    }

}