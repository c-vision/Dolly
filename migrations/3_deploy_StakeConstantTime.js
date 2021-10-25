const StakeConstantTime = artifacts.require('StakeConstantTime');

module.exports = async function(deployer, network, accounts) {

    process.env.NETWORK = deployer.network; // now accessible from unit tests

    await deployer.deploy(StakeConstantTime);
    console.log("StakeConstantTime deployed at " + StakeConstantTime.address);

}