var fs = require('fs');
const Web3 = require('web3')

const web3 = new Web3("https://kovan.infura.io/v3/a38fa3ea997e4691b62281a9d610d0c7");

var jsonFile = "./build/contracts/AggregatorV3Interface.json";
var parsed = JSON.parse(fs.readFileSync(jsonFile));
var aggregatorV3InterfaceABI = parsed.abi;

const addr = "0x9326BFA02ADD2366b30bacB125260Af641031331";

var decimals = 0;
var description = "";
var version = 0;
var price = 0;

const priceFeed = new web3.eth.Contract(aggregatorV3InterfaceABI, addr);

priceFeed.methods.decimals().call().then(x => {
    decimals = x;
    console.log("decimals = " + x);
    priceFeed.methods.latestRoundData().call()
        .then(roundData => {
            price = roundData[1] / 10 ** decimals;
            console.log("price = " + price)
        });
});
priceFeed.methods.version().call().then(x => {
    version = x;
    console.log("version = " + version)
});
priceFeed.methods.description().call().then(x => {
    description = x;
    console.log("description = " + description)
});