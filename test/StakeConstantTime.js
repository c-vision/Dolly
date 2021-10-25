const StakeConstantTime = artifacts.require("StakeConstantTime");

contract("StakeConstantTime", accounts => {

    let [Owner, Admin, Sales, Bob, Alice, Tom, Charlie, Sam, John, Bill] = accounts;
    let instance, address;
    let result;

    before('getting instance before all Test Cases', async function() {

        const network = process.env.NETWORK; // must be set on migration contract
        console.log("network name:" + network);

        instance = await StakeConstantTime.deployed();
        address = instance.address;

        console.log("StakeConstantTime address: " + address);

        const newtworkType = await web3.eth.net.getNetworkType();
        const networkId = await web3.eth.net.getId();
        console.log("network type:" + newtworkType);
        console.log("network id:" + networkId);

    })

    it("should deposit some ethers", async() => {

        await instance.Deposit(web3.utils.toWei('1', 'Ether'), { from: Owner });
        await instance.Deposit(web3.utils.toWei('2', 'Ether'), { from: Admin });
        await instance.Deposit(web3.utils.toWei('4', 'Ether'), { from: Sales });

    })

    it("should withdraw some ethers", async() => {

        result = await instance.Withdraw({ from: Sales }) / 10 ** 18;
        //console.log("Sales: " + result.toString());

        result = await instance.Withdraw({ from: Owner }) / 10 ** 18;
        //console.log("Owner: " + result.toString());

        result = await instance.Withdraw({ from: Admin }) / 10 ** 18;
        //console.log("Admin: " + result.toString());

    })

})