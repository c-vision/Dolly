var fs = require('fs');
const Web3 = require('web3')

var web3 = new Web3(new Web3.providers.HttpProvider('http://localhost:8545')); //Ganache fork to Kovan

//var jsonFile = "G://Sources//Projects//DollyCoin//build//contracts//Dolly.json";
var jsonFile = "./build/contracts/Dolly.json";
var parsed = JSON.parse(fs.readFileSync(jsonFile));
var dollyABI = parsed.abi;

// development address on Ganache Kovan fork
const addr = "0xAaF0F951Be0D638cf22A127fdf67438E2A607Ec8";

var decimals = 0;
var price = 0;

const dolly = new web3.eth.Contract(dollyABI, addr);

dolly.methods.currentExchangeRateinETH().call().then(x => {
    console.log("currentExchangeRateinETH = " + x);
});

dolly.methods.currentExchangeRateinUSD().call().then(x => {
    console.log("currentExchangeRateinUSD = " + x);
});

dolly.methods.currentExchangeIsActive().call().then(x => {
    console.log("currentExchangeIsActive = " + x);
});

dolly.methods.currentExchangeIsDynamic().call().then(x => {
    console.log("currentExchangeIsDynamic = " + x);
});

dolly.methods.ETHUSDPrice().call().then(x => {
    uprice = x[0];
    decimals = x[1];
    price = uprice / 10 ** decimals;
    console.log("Price = " + price);
    console.log("Decimals = " + decimals);
});

// pseudo random numbers
// for (i = 0; i < 100; i++) {
// random number between 0 and 14
//     dolly.methods.random(14, i).call().then(x => {
//         console.log("random = " + x);
//     })
// }