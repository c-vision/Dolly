// npm install --save-dev @openzeppelin/test-environment mocha chai
// npm install --save-dev @openzeppelin/test-helpers
const Dolly = artifacts.require("Dolly");

contract("Dolly", accounts => {

    /*

    Accounts:
    (0) 0x0258513d2a4a0ff3d92ad6cc925689a0851c29e2 //Owner
    (1) 0xb5bf63d0e3cd25eafa740e49ed69d07ceac903f0 //Admin
    (2) 0x35e4e0f29b55e58bd385dc051d0ff581382d2258 //Sales
    (3) 0x2534f4dd2aea85b13d943e88ff0f19063fad84bb //Bob
    (4) 0x203100f5e46d6a3178aeb1a90c03b99c32bc2313 //Alice
    (5) 0xa5afa05ffeb2cf01b7cffd1caef0754196718957 //Tom
    (6) 0xd423a0fa1e985b2561daeb073e070894dedbb143 //Charlie
    (7) 0x0516083824fe45f90442b7c8c7cc46f79ba954dc //Sam
    (8) 0x5d870fa0e1a7f92f172959d2892825bf6dc96052 //John
    (9) 0x892fef751148da4634d521c0629ecef39f69e9d9 //Bill

    Private Keys:
    (0) f7f559a20692f355a9a107817d524097e914998bd57cb57956395858f6711c2c
    (1) 7b1b15f44154265219aae9043779c2197a2fab11cb8ba39ab8f0e8de00c91e98
    (2) d2ce291a2e4f82f902dd7d93262edb6ed34b08acdc8fae2e4a17ca53c19de93b
    (3) 406b6ffad9acb45278a36ec3ece89c7d067c229a25678a0ea4d02773665d4e51
    (4) 4d511122b712c97c9e3e4a81964eb0ddc223cbd03ed32f832d160500798d8b87
    (5) 2cc6fe70e4ea7b70fdd5d1991cf07614822c9cbc9af684f0a316d0f7f45528b5
    (6) 7d87307f106233ea9d09bba67584d7984a5c4a08e627fe858efb79978c09963d
    (7) d0f9d386ccfa384d312ebedd00bd45ea3e43dd48320910e72a394ca17dc384d0
    (8) 24a7bd958b40a49ce55ffecfc979cb6a75407deb2d4b718e78a5bced70156742
    (9) d17ab1b174c61a98821743ec977d4c059faf7088f0c54f9e71b015f8f6fa84d3
    */

    let [Owner, Admin, Sales, Bob, Alice, Tom, Charlie, Sam, John, Bill] = accounts;

    const total_supply = 500000000;
    const admin_supply = 100000000;
    const avail_supply = total_supply - admin_supply;
    const sales_supply = 50000000;
    const factor = 10 ** 18;
    let name, symbol, decimals;
    let instance, address, coinbase;

    const print = false; // exec console.log

    const allTrue = false; // exec all tests
    const allFalse = false; //exec no tests
    // exec specified tests if alltrue and allfalse are both false
    const testExchangeRate = true;
    const testSales = true;
    const testBuyWithEthers = true;
    const allowDynamicExchange = true; //must be true for public network only (call ChainLink)
    const testWithdrawal = true;
    const testSuicide = true;
    const testMint = true;
    const testBurn = true;
    const testSendTokens = true;
    const testTransferAllowedTokens = true;
    const testIncDecAllowance = true;

    before('getting instance before all Test Cases', async function() {

        const network = process.env.NETWORK; // must be set on migration contract
        console.log("network name:" + network);

        //instance = await Dolly.new({ from: Owner });
        instance = await Dolly.deployed();
        address = instance.address;

        coinbase = await web3.eth.getCoinbase();
        assert.ok(coinbase, "error reading coinbase address");

        const newtworkType = await web3.eth.net.getNetworkType();
        const networkId = await web3.eth.net.getId();
        console.log("network type:" + newtworkType);
        console.log("network id:" + networkId);

    })

    it("should confirm token name, token symbol and decimals",
        async() => {
            name = await instance.name.call({ from: Owner });
            assert.ok(name, "error reading token name");
            symbol = await instance.symbol.call({ from: Owner });
            assert.ok(symbol, "error reading token symbol");
            decimals = (await instance.decimals.call({ from: Owner })).toNumber();
            assert.ok(decimals, "error reading decimals");
            if (print) {
                console.log("Token name: " + name);
                console.log("Token symbol: " + symbol);
                console.log("Token decimals: " + decimals);
            }
            assert(!!name, "Invalid token name");
            assert(!!symbol, "Invalid token symbol");
            assert(decimals > 0, "Invalid number of decimals");

        });

    it("should put " + total_supply + " tokens into the Owner'account",
        async() => {
            //get Owner supply
            const balance = await instance.balanceOf.call(Owner, { from: Owner });
            assert.ok(balance);
            if (print) console.log("Owner balance: " + balance.valueOf());
            //get Owner tokens
            const tokens = await instance.balanceTokensOf.call(Owner, { from: Owner });
            assert.ok(tokens);
            if (print) console.log("Owner tokens: " + tokens.valueOf());
            //must much total supply
            assert.equal(tokens.valueOf(), total_supply, total_supply + " tokens wasn't in the Owner account");
            //print contract's total supply
            let supply = await instance.totalSupply.call({ from: Owner })
            assert.ok(supply);
            if (print) console.log("total supply: " + supply);
        });

    it("should update the Admin'account address",
        async() => {
            //update Admin address
            const result = await instance.updateAdminAddress(Admin, { from: Owner });
            assert.ok(result);
            //get new Admin address
            const newAdmin = await instance.admin.call({ from: Owner });
            assert.ok(newAdmin);
            if (print) console.log("New Admin address: " + newAdmin.toString());
            //must match
            assert.equal(Admin, newAdmin, "The Admin address is still wrong");
        });

    it("should put " + admin_supply + " tokens into the Admin'account and reduce Owner's tokens",
        async() => {
            //reserve 100 millions tokens for the Administrator
            const result = await instance.updateAdminTokens(admin_supply, { from: Admin });
            assert.ok(result);
            //get Admin balance in twei (token wei)
            const AdminBalance = await instance.balanceOf.call(Admin, { from: Owner });
            assert.ok(AdminBalance);
            if (print) console.log("Admin balance: " + AdminBalance.valueOf());
            //get Admin balance in tokens
            const AdminTokens = await instance.balanceTokensOf.call(Admin, { from: Owner });
            assert.ok(AdminTokens);
            if (print) console.log("Admin Tokens: " + AdminTokens.valueOf());
            assert.equal(AdminTokens.valueOf(), admin_supply, admin_supply + "tokens wasn't in the Admin account");
            //get remaining Owner balance
            const OwnerTokens = await instance.balanceTokensOf.call(Owner, { from: Owner });
            assert.ok(OwnerTokens);
            if (print) console.log("Owner tokens: " + OwnerTokens.valueOf());
            //onwer balance must much available supply
            assert.equal(OwnerTokens.valueOf(), avail_supply, avail_supply + " tokens wasn't in the Owner account");
        });

    if (allTrue ? true : allFalse ? false : testSales) {
        it("should update the Sales'account address",
            async() => {
                //update the Sales address
                const result = await instance.updateSalesAddress(Sales, { from: Admin });
                assert.ok(result);
                //get updated Sales address
                const newSales = await instance.sales.call({ from: Owner });
                assert.ok(newSales);
                if (print) console.log("New Sales address: " + newSales.toString());
                //must be equals
                assert.equal(Sales, newSales, "The Sales address is still wrong");
            });

        it("reserve " + sales_supply + " tokens into the Sales'account without reducing Owner's tokens",
            async() => {
                //reserve tokens for Sales
                const result = await instance.updateSalesTokens(sales_supply, { from: Admin });
                assert.ok(result);
                //get Sales balance
                const SalesBalance = await instance.balanceOf.call(Sales, { from: Owner });
                assert.ok(SalesBalance);
                if (print) console.log("Sales balance: " + SalesBalance.valueOf());
                assert.equal(SalesBalance.valueOf(), 0, "wrong amount into Sales account");
                //get remaining Owner balance
                const OwnerBalance = await instance.balanceOf.call(Owner, { from: Owner });
                assert.ok(OwnerBalance);
                if (print) console.log("Owner balance: " + OwnerBalance.valueOf());
                //get remaining Owner tokens
                const OwnerTokens = await instance.balanceTokensOf.call(Owner, { from: Owner });
                assert.ok(OwnerTokens);
                if (print) console.log("Owner tokens: " + OwnerTokens.valueOf());
                assert.equal(OwnerTokens.valueOf(), avail_supply, avail_supply + " tokens wasn't in the Owner account");
                //check for Sales address approved allowance
                const allowance = await instance.allowance.call(Owner, Sales, { from: Admin });
                assert.ok(allowance);
                if (print) console.log("Owner allowance for Sales: " + allowance);
            });

        it("try to reserve tokens into the Sales'account from a wrong address",
            async() => {
                try {
                    const result = await instance.updateSalesTokens(sales_supply, { from: Bob });
                } catch (e) {
                    if (print) console.log(e.toString());
                }
            });

        it("should transfers tokens from Sales'account allowance to other accounts correctly",
            async() => {

                const allowance = await instance.allowance.call(Owner, Sales, { from: Sales });
                assert.ok(allowance);
                if (print) console.log("Owner allowance for Sales: " + allowance);

                //read and print current contract's balance in tokens
                const OwnerTokensBefore = await instance.balanceTokensOf.call(Owner, { from: Owner });
                assert.ok(OwnerTokensBefore);
                if (print) console.log("Owner token balance before = " + OwnerTokensBefore.valueOf());

                //read and print current Bob's balance in tokens
                const BobTokensBefore = await instance.balanceTokensOf.call(Bob, { from: Bob });
                assert.ok(BobTokensBefore);
                if (print) console.log("Bob token balance before = " + BobTokensBefore.valueOf());

                //read and print current Alice's balance in tokens
                const AliceTokensBefore = await instance.balanceTokensOf.call(Alice, { from: Alice });
                assert.ok(AliceTokensBefore);
                if (print) console.log("Alice token balance before = " + AliceTokensBefore.valueOf());

                const tokens1 = web3.utils.toBN(100 * factor);
                const result1 = await instance.transferFrom(Owner, Bob, tokens1, { from: Sales });
                assert.ok(result1);

                const tokens2 = web3.utils.toBN(200 * factor);
                const result2 = await instance.transferFrom(Owner, Alice, tokens2, { from: Sales });
                assert.ok(result2);

                //read and print current contract's balance in tokens
                const OwnerTokensAfter = await instance.balanceTokensOf.call(Owner, { from: Owner });
                assert.ok(OwnerTokensAfter);
                if (print) console.log("Owner token balance after = " + OwnerTokensAfter.valueOf());

                //read and print current Bob's balance in tokens
                const BobTokensAfter = await instance.balanceTokensOf.call(Bob, { from: Bob });
                assert.ok(BobTokensAfter);
                if (print) console.log("Bob token balance after = " + BobTokensAfter.valueOf());

                //read and print current Alice's balance in tokens
                const AliceTokensAfter = await instance.balanceTokensOf.call(Alice, { from: Alice });
                assert.ok(AliceTokensAfter);
                if (print) console.log("Alice token balance after = " + AliceTokensAfter.valueOf());

            })

    }

    /**
     * testBuyWithEthers with static rate token / ethers
     */
    if (allTrue ? true : allFalse ? false : testBuyWithEthers) {
        it("Bob should buy tokens coin correctly sending ethers", async() => {

            const tokens_rate = 5000;
            const ether_sent = 0.1;
            const expected_tokens = tokens_rate * ether_sent;

            // set exchange rate to tokens_rate tokens per 1 dollar
            let dyna_result = await instance.exchangeSetDynamic(false, { from: Owner });
            assert.ok(dyna_result);

            //read the dynamic status of the exchange
            let isDynamic = await instance.currentExchangeIsDynamic.call();
            if (print) console.log("currentExchangeIsDynamic = " + isDynamic);

            // set exchange rate to tokens_rate tokens per 1 ether
            let result = await instance.exchangeSetRateETH(tokens_rate, { from: Owner });
            assert.ok(result);

            // read current exchange rate DOLLY/ETH
            let rate = await instance.currentExchangeRateinETH.call()
            assert.ok(rate)
            if (print) console.log("Current rate DOLLY/ETH = " + rate);

            //read and print current contract's balance in ether
            let ContractEtherBefore = await web3.eth.getBalance(instance.address);
            assert.ok(ContractEtherBefore);
            if (print) console.log("Contract ether balance before = " + ContractEtherBefore / factor);

            //read and print current Bob's balance in ether
            let UserEtherBefore = await web3.eth.getBalance(Bob)
            assert.ok(UserEtherBefore);
            if (print) console.log("Bob ether balance before = " + UserEtherBefore / factor);

            //read and print current contract's balance in tokens
            const OwnerTokensBefore = await instance.balanceTokensOf.call(Owner, { from: Owner });
            assert.ok(OwnerTokensBefore);
            if (print) console.log("Owner token balance before = " + OwnerTokensBefore.valueOf());

            //read and print current Bob's balance in tokens
            const UserTokensBefore = await instance.balanceTokensOf.call(Bob, { from: Owner });
            assert.ok(UserTokensBefore);
            if (print) console.log("Bob token balance before = " + UserTokensBefore.valueOf());

            //Bob is sending 1 ether to the contract in exchange of tokens
            await web3.eth.sendTransaction({
                from: Bob,
                to: instance.address,
                value: web3.utils.toWei(ether_sent.toString(), 'Ether')
            }).then(function(receipt) {
                if (print) console.log(receipt)
            }).catch(console.log)

            //read and print current contract's balance in ether
            let ContractEtherAfter = await web3.eth.getBalance(address);
            if (print) console.log("Contract ether balance after = " + ContractEtherAfter / factor);

            //read and print current Bob's balance in ether
            let UserEtherAfter = await web3.eth.getBalance(Bob)
            if (print) console.log("Bob ether balance after = " + UserEtherAfter / factor);

            //read and print current contract's balance in tokens
            const OwnerTokensAfter = await instance.balanceTokensOf.call(Owner, { from: Owner });
            if (print) console.log("Owner token balance after = " + OwnerTokensAfter.valueOf());

            //read and print current Bob's balance in tokens
            const UserTokensAfter = await instance.balanceTokensOf.call(Bob, { from: Owner });
            const obtained_tokens = UserTokensAfter.valueOf() - UserTokensBefore.valueOf();

            if (print) console.log("Bob token balance after = " + UserTokensAfter.valueOf());
            if (print) console.log("Bob expected tokens = " + expected_tokens);
            if (print) console.log("Bob obatained tokens = " + obtained_tokens);
            assert.equal(obtained_tokens, expected_tokens, "number of tokens is wrong");

        });
    }

    /**
     * testBuyWithEthers at dynamic rate token / USD
     * it works on Kovan networks only if dynamic price is on
     * Network: Kovan
     * Aggregator: ETH/USD
     * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
     */
    if (allTrue ? true : allFalse ? false : testBuyWithEthers && allowDynamicExchange) {
        it("Bob should buy tokens coin correctly sending ethers converted to USD", async() => {

            const tokens_rate_USD = 2;
            const ether_sent = 0.1;

            // set exchange rate to tokens_rate tokens per 1 dollar
            let dyna_result = await instance.exchangeSetDynamic(true, { from: Owner });
            assert.ok(dyna_result);

            //read the dynamic status of the exchange
            let isDynamic = await instance.currentExchangeIsDynamic.call();
            if (print) console.log("currentExchangeIsDynamic = " + isDynamic);

            // set exchange rate to tokens_rate tokens per 1 dollar
            let result = await instance.exchangeSetRateUSD(tokens_rate_USD, { from: Owner });
            assert.ok(result);

            // read current exchange rate DOLLY/USD
            let rate = await instance.currentExchangeRateinUSD.call()
            assert.ok(rate)
            if (print) console.log("Current rate DOLLY/USD = " + rate);

            //read and print current contract's balance in ether
            let ContractEtherBefore = await web3.eth.getBalance(instance.address);
            assert.ok(ContractEtherBefore);
            if (print) console.log("Contract ether balance before = " + ContractEtherBefore / factor);

            //read and print current Bob's balance in ether
            let UserEtherBefore = await web3.eth.getBalance(Bob)
            assert.ok(UserEtherBefore);
            if (print) console.log("Bob ether balance before = " + UserEtherBefore / factor);

            let estimatedPriceETHUSD = await instance.ETHUSDPrice.call({ from: Owner });
            assert.ok(estimatedPriceETHUSD[0]);
            if (print) console.log("Estimated ETH/USD = " + estimatedPriceETHUSD[0]);

            //read and print current contract's balance in tokens
            const OwnerTokensBefore = await instance.balanceTokensOf.call(Owner, { from: Owner });
            assert.ok(OwnerTokensBefore);
            if (print) console.log("Owner token balance before = " + OwnerTokensBefore.valueOf());

            //read and print current Bob's balance in tokens
            const UserTokensBefore = await instance.balanceTokensOf.call(Bob, { from: Owner });
            assert.ok(UserTokensBefore);
            if (print) console.log("Bob token balance before = " + UserTokensBefore.valueOf());

            //Bob is sending ether_sent ether to the contract in exchange of tokens
            await web3.eth.sendTransaction({
                from: Bob,
                to: instance.address,
                value: web3.utils.toWei(ether_sent.toString(), 'Ether')
            }).then(function(receipt) {
                if (print) console.log(receipt)
            }).catch(console.log)

            //read and print current contract's balance in ether
            let ContractEtherAfter = await web3.eth.getBalance(address);
            if (print) console.log("Contract ether balance after = " + ContractEtherAfter / factor);

            //read and print current Bob's balance in ether
            let UserEtherAfter = await web3.eth.getBalance(Bob)
            if (print) console.log("Bob ether balance after = " + UserEtherAfter / factor);

            //read and print current contract's balance in tokens
            const OwnerTokensAfter = await instance.balanceTokensOf.call(Owner, { from: Owner });
            if (print) console.log("Owner token balance after = " + OwnerTokensAfter.valueOf());

            //read and print current Bob's balance in tokens
            const UserTokensAfter = await instance.balanceTokensOf.call(Bob, { from: Owner });
            const obtained_tokens = UserTokensAfter.valueOf().toNumber();
            if (print) console.log("Bob token balance after = " + obtained_tokens);

        });
    }

    if (allTrue ? true : allFalse ? false : testWithdrawal) {
        it("Owner withdraw should works correctly", async() => {

            //read and print current contract's balance in ether
            let ContractEtherBefore = await web3.eth.getBalance(address);
            if (print) console.log("Contract ether balance before = " + ContractEtherBefore / factor);

            //read and print current onwer's balance in ether
            let OwnerEtherBefore = await web3.eth.getBalance(Owner)
            if (print) console.log("Owner ether balance before = " + OwnerEtherBefore / factor);

            //move all the ethers from contract to Owner account
            const result = await instance.withdrawal({ from: Owner });
            assert.ok(result);

            //read and print current contract's balance in ether
            let ContractEtherAfter = await web3.eth.getBalance(address);
            if (print) console.log("Owner ether balance after = " + ContractEtherAfter / factor);

            //read and print current Owner's balance in ether
            let OwnerEtherAfter = await web3.eth.getBalance(Owner)
            if (print) console.log("Owner ether balance after = " + OwnerEtherAfter / factor);

            assert(ContractEtherAfter == 0, "amount of ethers in the contract is wrong")
                //assert(OwnerEtherBefore < OwnerEtherAfter, "amount of ethers withdrawed is wrong")

        });
    }

    if (allTrue ? true : allFalse ? false : testExchangeRate) {
        it('Owner should be able to change price',
            async() => {
                let isActiveBefore = await instance.currentExchangeIsActive.call();
                if (print) console.log("currentExchangeIsActive = " + isActiveBefore);
                let isDynamicBefore = await instance.currentExchangeIsDynamic.call();
                if (print) console.log("currentExchangeIsDynamic = " + isDynamicBefore);
                let res = await instance.exchangeSetRateETH(2000, { from: Owner })
                assert.ok(res)
                let rate = await instance.currentExchangeRateinETH.call()
                assert.ok(rate)
                assert.equal(rate.toNumber(), 2000, "exchange rate is wrong");
            })

        it('Only Owner should be able to change price',
            async() => {
                try {
                    await instance.exchangeSetRateETH(2000, { from: Bob })
                } catch (e) {
                    assert.ok(e)
                }
                let rate = await instance.currentExchangeRateinETH.call()
                assert.ok(rate)
                assert.equal(rate.toNumber(), 2000, "exchange rate is wrong");
            })
    }

    if (allTrue ? true : allFalse ? false : testBurn) {
        it("should burn 50 Bob's tokens reducing total supply",
            async() => {

                //print contract's total supply
                let totalSupplyBefore = await instance.totalSupply.call({ from: Bob })
                assert.ok(totalSupplyBefore);
                if (print) console.log("total supply before: " + totalSupplyBefore);

                //read and print current Bob's balance in tokens
                const BobTokensBefore = await instance.balanceTokensOf.call(Bob, { from: Bob });
                assert.ok(BobTokensBefore);
                if (print) console.log("Bob token balance before = " + BobTokensBefore.valueOf());

                const tokens = web3.utils.toBN(50 * factor);
                const result = await instance.burn(tokens, { from: Bob });
                assert.ok(result);

                //print contract's total supply
                let totalSupplyAfter = await instance.totalSupply.call({ from: Bob })
                assert.ok(totalSupplyAfter);
                if (print) console.log("total supply before: " + totalSupplyAfter);

                //read and print current Bob's balance in tokens
                const BobTokensAfter = await instance.balanceTokensOf.call(Bob, { from: Bob });
                assert.ok(BobTokensAfter);
                if (print) console.log("Bob token balance after = " + BobTokensAfter.valueOf());

            })
    }

    if (allTrue ? true : allFalse ? false : testSendTokens) {
        it("Bob should send tokens to Alice",
            async() => {

                //read and print current Bob's balance in tokens
                const BobTokensBefore = await instance.balanceTokensOf.call(Bob, { from: Bob });
                assert.ok(BobTokensBefore);
                if (print) console.log("Bob token balance before = " + BobTokensBefore.valueOf());

                //read and print current Alice's balance in tokens
                const AliceTokensBefore = await instance.balanceTokensOf.call(Alice, { from: Alice });
                assert.ok(AliceTokensBefore);
                if (print) console.log("Alice token balance before = " + AliceTokensBefore.valueOf());

                const tokens = web3.utils.toBN(25 * factor);
                const result = await instance.transfer(Alice, tokens, { from: Bob });
                assert.ok(result);

                //read and print current Bob's balance in tokens
                const BobTokensAfter = await instance.balanceTokensOf.call(Bob, { from: Bob });
                assert.ok(BobTokensAfter);
                if (print) console.log("Bob token balance after = " + BobTokensAfter.valueOf());

                //read and print current Alice's balance in tokens
                const AliceTokensAfter = await instance.balanceTokensOf.call(Alice, { from: Alice });
                assert.ok(AliceTokensAfter);
                if (print) console.log("Alice token balance after = " + AliceTokensAfter.valueOf());
            })
    }

    if (allTrue ? true : allFalse ? false : testTransferAllowedTokens) {
        it("Alice should approve BOB for transfer tokens to Tom",
            async() => {

                //read and print current Alice's balance in tokens
                const AliceTokensBefore = await instance.balanceTokensOf.call(Alice, { from: Bob });
                assert.ok(AliceTokensBefore);
                if (print) console.log("Alice token balance before = " + AliceTokensBefore.valueOf());

                //read and print current Bob's balance in tokens
                const TomTokensBefore = await instance.balanceTokensOf.call(Tom, { from: Bob });
                assert.ok(TomTokensBefore);
                if (print) console.log("Tom token balance before = " + TomTokensBefore.valueOf());

                //Alice is approving Bob
                let tokens = web3.utils.toBN(30 * factor);
                let result = await instance.approve(Bob, tokens, { from: Alice });
                assert.ok(result);

                //check for Bob address approved allowance
                let allowance = await instance.allowance.call(Alice, Bob, { from: Bob });
                assert.ok(allowance);
                if (print) console.log("Alice allowance for Bob before: " + allowance / factor);

                //Bob is sending Alice's tokens to Tom
                tokens = web3.utils.toBN(25 * factor);
                result = await instance.transferFrom(Alice, Tom, tokens, { from: Bob });
                assert.ok(result);

                //read and print current Bob's balance in tokens
                const TomTokensAfter = await instance.balanceTokensOf.call(Tom, { from: Bob });
                assert.ok(TomTokensAfter);
                if (print) console.log("Tom token balance after = " + TomTokensAfter.valueOf());

                //read and print current Alice's balance in tokens
                const AliceTokensAfter = await instance.balanceTokensOf.call(Alice, { from: Alice });
                assert.ok(AliceTokensAfter);
                if (print) console.log("Alice token balance after = " + AliceTokensAfter.valueOf());

                //check for Bob address approved allowance
                allowance = await instance.allowance.call(Alice, Bob, { from: Bob });
                assert.ok(allowance);
                if (print) console.log("Alice allowance for Bob after: " + allowance / factor);
            })
    }

    if (allTrue ? true : allFalse ? false : testIncDecAllowance) {
        it("Alice should increase and decrease allowance for BOB",
            async() => {

                //check for Bob address approved allowance
                let allowance = await instance.allowance.call(Alice, Bob, { from: Bob });
                assert.ok(allowance);
                if (print) console.log("Alice allowance for Bob before: " + allowance / factor);

                //Alice is approving Bob
                let tokens = web3.utils.toBN(30 * factor);
                let result = await instance.increaseAllowance(Bob, tokens, { from: Alice });
                assert.ok(result);

                //check for Bob address approved allowance
                allowance = await instance.allowance.call(Alice, Bob, { from: Bob });
                assert.ok(allowance);
                if (print) console.log("Alice allowance for Bob after increase: " + allowance / factor);

                //Bob is sending Alice's tokens to Tom
                tokens = web3.utils.toBN(20 * factor);
                result = await instance.decreaseAllowance(Bob, tokens, { from: Alice });
                assert.ok(result);

                //check for Bob address approved allowance
                allowance = await instance.allowance.call(Alice, Bob, { from: Bob });
                assert.ok(allowance);
                if (print) console.log("Alice allowance for Bob after reduction: " + allowance / factor);
            })
    }

    if (allTrue ? true : allFalse ? false : testMint) {
        it("should create (mint) 50 new tokens for Bob increasing total supply",
            async() => {

                //print contract's total supply
                let totalSupplyBefore = await instance.totalSupply.call({ from: Bob })
                assert.ok(totalSupplyBefore);
                if (print) console.log("total supply before: " + totalSupplyBefore);

                //read and print current Bob's balance in tokens
                const BobTokensBefore = await instance.balanceTokensOf.call(Bob, { from: Bob });
                assert.ok(BobTokensBefore);
                if (print) console.log("Bob token balance before = " + BobTokensBefore.valueOf());

                const tokens = web3.utils.toBN(50 * factor);
                //create new tokens, function call reserved to Owner or Admin
                const result = await instance.mint(Bob, tokens, { from: Owner });
                assert.ok(result);

                //print contract's total supply
                let totalSupplyAfter = await instance.totalSupply.call({ from: Bob })
                assert.ok(totalSupplyAfter);
                if (print) console.log("total supply before: " + totalSupplyAfter);

                //read and print current Bob's balance in tokens
                const BobTokensAfter = await instance.balanceTokensOf.call(Bob, { from: Bob });
                assert.ok(BobTokensAfter);
                if (print) console.log("Bob token balance after = " + BobTokensAfter.valueOf());

            })
    }

    if (allTrue ? true : allFalse ? false : testSuicide) {
        it("It should kill the contract and send ethers to Owner'address",
            async() => {
                let ContractEtherBefore = await web3.eth.getBalance(address);
                if (print) console.log("Contract ether balance before = " + ContractEtherBefore / factor);

                //read and print current Owner's balance in ether
                let OwnerEtherBefore = await web3.eth.getBalance(Owner)
                if (print) console.log("Owner ether balance before = " + OwnerEtherBefore / factor);

                //move all the ethers from contract to Owner account
                const result = await instance.killContract({ from: Owner });
                assert.ok(result);

                //read and print current contract's balance in ether
                let ContractEtherAfter = await web3.eth.getBalance(address);
                if (print) console.log("Owner ether balance after = " + ContractEtherAfter / factor);

                //read and print current Owner's balance in ether
                let OwnerEtherAfter = await web3.eth.getBalance(Owner)
                if (print) console.log("Owner ether balance after = " + OwnerEtherAfter / factor);

            })
    }
});