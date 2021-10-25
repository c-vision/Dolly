var fs = require('fs');
const Web3 = require('web3')
var contract = require("truffle-contract");

var web3 = new Web3(new Web3.providers.HttpProvider('http://localhost:8545')); //Ganache fork to Kovan

var jsonFile = "./build/contracts/StakeConstantTime.json";
var parsed = JSON.parse(fs.readFileSync(jsonFile));
var StakeConstantTimeABI = parsed.abi;

jsonFile = "./build/contracts/StakeWithRewardChanging.json";
parsed = JSON.parse(fs.readFileSync(jsonFile));
var StakeWithRewardChangingABI = parsed.abi;

jsonFile = "./build/contracts/Stakes.json";
parsed = JSON.parse(fs.readFileSync(jsonFile));
var StakesABI = parsed.abi;

// development address on Ganache Kovan fork
const StakeConstantTimeAddr = "0x6588EE6e5FFbc7D1DEEb44eF0f79E9abA7C7334F";
const StakeWithRewardChangingAddr = "0xe897A54c56d0cCf2f2f124391C0304c37F210A9d";
const StakesAddr = "0x7674eF89Cc173bF405343980d38ab81FDf008607";

const StakeConstantTime = contract(StakeConstantTimeABI, StakeConstantTimeAddr);
const StakeWithRewardChanging = contract(StakeWithRewardChangingABI, StakeWithRewardChangingAddr);
const Stakes = new web3.eth.Contract(StakesABI, StakesAddr);

StakeConstantTime.setProvider(web3);

const owner = "0xe1dffA82C36BE0f0A26A49C7a88E298335113540";
const user1 = "0x20B1914651924F9A684E9C7d0b92C4d9413Fb79d";
const user2 = "0x37f3B53035FfC8b0a7C30D2811675FBBc0C3bA47";
const user3 = "0x46308FBF59847DB95FfE6cBC1924967c6f03DE61";
const user4 = "0x0291d7F2885E46860EDf131112cB4299774265dA";
const user5 = "0x6956424a0790BF77982c3951829B2c257a32d259";
const user6 = "0x941D40D862957d289156dB8ee8524632295f81B3";
const user7 = "0xc3a88BB534a113F03577e18a962E28C4b14179D8";
const user8 = "0x3aAAa042e59d9B77471053D008276e67123Df70a";
const user9 = "0xB54605D92fdbeaaADac5851E7037C444EE2E5067";

StakeConstantTime.Deposit(web3.utils.toWei('1', 'Ether')).call({ from: owner })
    .then(x => { console.log("StakeConstantTime deposited 1 ether"); })
    .catch(console.log);

StakeConstantTime.Deposit(web3.utils.toWei('2', 'Ether')).call({ from: user1 })
    .then(x => { console.log("StakeConstantTime deposited 2 ether"); })
    .catch(console.log);

StakeConstantTime.Deposit(web3.utils.toWei('4', 'Ether')).call({ from: user2 })
    .then(x => { console.log("StakeConstantTime deposited 4 ether"); })
    .catch(console.log);

/* 
    The difference between in a call and a transaction is the following:
    transactions are created by your client, signed and broadcasted to the network. They will eventually 
    alter the state of the blockchain, for example, by manipulating balances or values in smart contracts.

    calls are transactions executed locally on the user's local machine which alone evaluates the result. 
    These are read-only and fast. They can't change the blockchain in any way because they are never sent 
    to the network. Some examples "read-only/dry run/practice".

    Calls are useful for debugging smart contracts as they do not cost transaction fees or gas.

    Automatically determines the use of call or sendTransaction based on the method type (constant keyword exists or not?)
    myContractInstance.myMethod(param1 [, param2, ...] [, transactionObject] [, defaultBlock] [, callback]);

    Explicitly calling this method
    myContractInstance.myMethod.call(param1 [, param2, ...] [, transactionObject] [, defaultBlock] [, callback]);

    Explicitly sending a transaction to this method
    myContractInstance.myMethod.sendTransaction(param1 [, param2, ...] [, transactionObject] [, callback]);
*/

StakeConstantTime.Withdraw.then(function(result) { console.log(result); })

// .then(x => { console.log("StakeConstantTime withdrawed" + x); })
// .catch(console.log);


// StakeConstantTime.methods.Withdraw().call({ from: user1 })
//     .then(x => { console.log("StakeConstantTime withdrawed" + x); })
//     .catch(console.log);

// StakeConstantTime.methods.Withdraw().call({ from: user2 })
//     .then(x => { console.log("StakeConstantTime withdrawed" + x); })
//     .catch(console.log);

// dolly.methods.currentExchangeRateinUSD().call().then(x => {
//     console.log("currentExchangeRateinUSD = " + x);
// });

// dolly.methods.currentExchangeIsActive().call().then(x => {
//     console.log("currentExchangeIsActive = " + x);
// });

// dolly.methods.currentExchangeIsDynamic().call().then(x => {
//     console.log("currentExchangeIsDynamic = " + x);
// });

// dolly.methods.readPrice().call().then(x => {
//     uprice = x[0];
//     decimals = x[1];
//     price = uprice / 10 ** decimals;
//     console.log("Price = " + price);
//     console.log("Decimals = " + decimals);
// });

// // pseudo random numbers
// for (i = 0; i < 100; i++) {
//     // random number between 0 and 14
//     dolly.methods.random(14, i).call().then(x => {
//         console.log("random = " + x);
//     })
// }