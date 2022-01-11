const Dolly = artifacts.require('Dolly');

module.exports = async function(deployer, network, accounts) {

    process.env.NETWORK = deployer.network; // now accessible from unit tests

    try {
        // https://uniswap.org/docs/v1/frontend-integration/connect-to-uniswap/
        // const mainnet = '0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95'
        // const ropsten = '0x9c83dCE8CA20E9aAF9D3efc003b2ea62aBC08351'
        // const rinkeby = '0xf5D915570BC477f9B8D6C0E980aA81757A3AaC36'
        // const kovan = '0xD3E51Ef092B2845f10401a0159B2B96e8B6c3D30'
        // const görli = '0x6Ce570d02D73d4c384b46135E87f8C592A8c86dA'
        let UniswapFactoryAddressV1;
        // https://uniswap.org/docs/v2/smart-contracts/factory/#address
        // UniswapV2Factory is deployed at 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f on the 
        // Ethereum mainnet, and the Ropsten, Rinkeby, Görli, and Kovan testnets. It was built 
        // from commit 8160750.
        let UniswapFactoryAddressV2 = "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f";
        // https://uniswap.org/docs/v2/smart-contracts/router02
        // UniswapV2Router02 is deployed at 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D on the 
        // Ethereum mainnet, and the Ropsten, Rinkeby, Görli, and Kovan testnets. It was built 
        // from commit 6961711.
        let UniswapV2Router02 = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
        // https://uniswap.org/docs/v2/smart-contracts/router01/
        // UniswapV2Router01 is deployed at 0xf164fC0Ec4E93095b804a4795bBe1e041497b92a on the 
        // Ethereum mainnet, and the Ropsten, Rinkeby, Görli, and Kovan testnets. It was built from 
        // commit 2ad7da2.
        let UniswapV2Router01 = "0xf164fC0Ec4E93095b804a4795bBe1e041497b92a";

        // https://docs.chain.link/docs/ethereum-addresses/?_ga=2.128060428.1003036136.1622819283-1635956328.1619102449
        // Make sure you have LINK coins in your wallet that you are making the request from. If you 
        // don't have LINK, you can visit Uniswap.io or Kyberswap to convert Ether to LINK. You will 
        // need .1 LINK per request.
        /**
         * Network: Mainnet
         * Aggregator: ETH/USD
         * Address: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
         */
        //eur_usd = "0x0c15Ab9A0DB086e062194c273CC79f41597Bbf13";
        //dai_usd = "0x777A68032a88E5A84678A77Af2CD65A7b3c0775a";
        let chainLinkETHUSD = "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419"; // mainnnet

        let SushiSwapRouterAddressV2;

        let canBeDeployed = true;

        let chainId = 0;

        switch (network) {
            case "develop":
                UniswapFactoryAddressV1 = "0x00"; // unavailable
                UniswapFactoryAddressV2 = "0x00"; // unavailable
                SushiSwapRouterAddressV2 = "0x00"; // unavailable
                UniswapV2Router01 = "0x00"; // unavailable
                UniswapV2Router02 = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D"; // will not works
                chainLinkETHUSD = "0x9326BFA02ADD2366b30bacB125260Af641031331"; // will not works
                chainId = 0; // interpret as *
                canBeDeployed = true; // will not compile if references to Uniswap/Chainlink are present
            case "mainnet":
            case "mainnet_fork":
            case "development": // For Ganache mainnet forks
                UniswapFactoryAddressV1 = "0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95";
                SushiSwapRouterAddressV2 = "0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F";
                chainId = 1; // same as network id (Ethereum Mainnet)
                break;
            case "ropsten":
            case "ropsten_fork":
                UniswapFactoryAddressV1 = "0x9c83dCE8CA20E9aAF9D3efc003b2ea62aBC08351";
                SushiSwapRouterAddressV2 = "0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506";
                chainLinkETHUSD = ""; // unavailable
                chainId = 3; // same as network id (Ethereum Testnet Ropsten)
                canBeDeployed = false;
                break;
            case "kovan":
            case "kovan_fork":
                UniswapFactoryAddressV1 = "0xD3E51Ef092B2845f10401a0159B2B96e8B6c3D30";
                SushiSwapRouterAddressV2 = "0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506"
                    /**
                     * Network: Kovan
                     * Aggregator: ETH/USD
                     * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
                     */
                chainLinkETHUSD = "0x9326BFA02ADD2366b30bacB125260Af641031331";
                chainId = 42; // same as network id (Ethereum Testnet Kovan)
                break;
            case "polygon_test":
                chainId = 80001; // same as network id (Matic Testnet Mumbai)
                canBeDeployed = false;
                break;
            case "polygon":
                chainId = 137; // same as network id (Matic Mainnet)
                canBeDeployed = false;
                break;
            case "bsc_testnet":
                // https://bsc.kiemtienonline360.com/
                // Contract Address: 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
                // Pools: BUSD-WBNB, USDT-WWBNB, BUSD-USDT, USDT-DAI, BUSD-ETH, USDT-ETH 
                UniswapV2Router02 = "0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3"; // BSC testnet address
                chainLinkETHUSD = "0x143db3CEEfbdfe5631aDD3E50f7614B6ba708BA7";
                chainId = 97; // same as network id (Binance Smart Chain Testnet)
                break;
            case "bsc":
                // https://docs.pancakeswap.finance/code/smart-contracts/pancakeswap-exchange/router-v2
                // PancakeSwap V2 is based on Uniswap V2. Read the Uniswap v2 documentation.
                UniswapV2Router02 = "0x10ED43C718714eb63d5aA57B78B54704E256024E"; // BSC mainnet address
                // https://docs.chain.link/docs/binance-smart-chain-addresses/
                chainLinkETHUSD = "0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e";
                chainId = 56; // same as network id (Binance Smart Chain Mainnet)
                break;
            default:
                throw Error(`Are you deploying to the correct network? (network selected: ${network})`)
        }
        // There is a separate exchange contract for every ERC20 token. The getExchange method in the factory 
        // contract can be used to find the Ethereum address associated with an ERC20 token address.
        // const exchangeAddress = factoryContract.methods.getExchange(tokenAddress)
        console.log("           Deployed Network: " + network);
        console.log("          Deployed Chain ID: " + chainId);
        console.log("Uniswap Address Provider V1: " + UniswapFactoryAddressV1);
        console.log("Uniswap Address Provider V2: " + UniswapFactoryAddressV2);
        console.log("  UniswapV2Router01 Address: " + UniswapV2Router01);
        console.log("  UniswapV2Router02 Address: " + UniswapV2Router02);
        console.log("Sushiswap Router Address V2: " + SushiSwapRouterAddressV2);
        console.log("          Chainlink ETH/USD: " + chainLinkETHUSD);

        // Example of deploying in Ganache Kovan fork
        // Deployed Network: kovan_fork
        // Deployed Chain ID: 42
        // Uniswap Address Provider V1: 0xD3E51Ef092B2845f10401a0159B2B96e8B6c3D30
        // Uniswap Address Provider V2: 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
        // UniswapV2Router01 Address: 0xf164fC0Ec4E93095b804a4795bBe1e041497b92a
        // UniswapV2Router02 Address: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        // Sushiswap Router Address V2: 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506
        // Chainlink ETH/USD: 0x9326BFA02ADD2366b30bacB125260Af641031331
        // Dolly deployed at 0x0e9C009f2511281Ac4E09fEc78213AeF3e5E2Bfb

        if (canBeDeployed) {

            // deploy Dolly
            // chainlink ETH/USD address, uniswap router V2 and sushiswap router V2 contracts
            await deployer.deploy(Dolly, chainId, chainLinkETHUSD, UniswapV2Router02);
            console.log("Dolly deployed at " + Dolly.address);

        } else {

            console.log("Dolly cannot be deployed on " + network);

        }

    } catch (e) {
        console.log(`Error in migration: ${e.message}`)
    }

};