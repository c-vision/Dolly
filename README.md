# Dolly (DOL)

[![Solidity](https://img.shields.io/badge/solidity-%5E0.8.6-363636?logo=solidity)](https://soliditylang.org)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

An ERC-20 token with built-in Uniswap V2 liquidity handling, a Chainlink ETH/USD price feed, and a staking module using a scalable reward-distribution algorithm — built with Truffle.

## Overview

- **Token**: `Dolly` (`DOL`), 18 decimals, fixed initial supply of 500,000,000 tokens minted to the owner at deployment
- **Uniswap V2 integration**: creates its own trading pair on deployment; the contract can receive ETH directly (via `receive()`/`fallback()`) and mint tokens back to the sender at the current rate
- **Chainlink price feed**: reads the ETH/USD price on-chain for owner/admin-facing calculations
- **Staking**: two independent staking implementations using the [scalable reward distribution](http://batog.info/papers/scalable-reward-distribution.pdf) approach, so reward accounting stays O(1) regardless of the number of stakers
- **Role model**: owner, admin, and sales roles (`OwnableExt`) with separate token allocations for admin and pre-sale accounts
- **Safety mechanisms**: pausable transfers, reentrancy guards, fee exclusion list, and an explicit `terminate`/`killContract` path for retiring the contract

## Contracts

| Contract | Purpose |
|---|---|
| `Dolly.sol` | The token itself — ERC-20 logic, Uniswap pair creation, ETH↔token exchange, admin/sales token management |
| `Stakes.sol` | Staking pool using the O(1) scalable reward distribution algorithm |
| `StakeWithRewardChanging.sol` | Alternative staking implementation supporting a changing reward rate |
| `StakeConstantTime.sol` | Staking variant optimized for constant-time operations |
| `ChainlinkFeed.sol` / `ChainLinkPriceFeedLib.sol` | Chainlink price oracle integration |
| `OwnableExt.sol` | Extended ownership model (owner / admin / sales roles) |
| `Utils.sol` / `Math/` | Shared utilities and math helpers |
| `OpenZeppelin/`, `Uniswap/`, `Chainlink/` | Vendored third-party interfaces/base contracts |

## Requirements

- [Node.js](https://nodejs.org/) and npm
- [Truffle](https://trufflesuite.com/) (`npm install -g truffle`)
- [Ganache](https://trufflesuite.com/ganache/) for local development, or an RPC endpoint (e.g. [Infura](https://infura.io)) for testnet/mainnet deployment

## Setup

```bash
npm install
```

Create a `.env` file in the project root (never commit this file) with the values your chosen network needs, e.g.:

```
INFURA_API_KEY=your-infura-project-id
DEPLOY_MNEMONIC=your twelve word mnemonic phrase goes here
```

`truffle-config.js` reads deployment credentials from environment variables — **never hardcode a mnemonic, private key, or API key directly in source, and never commit `.env` or any file containing one.**

## Development

```bash
# Start a local blockchain
ganache

# Compile contracts
truffle compile

# Run the test suite against Ganache
truffle test

# Deploy to a configured network
truffle migrate --network <network-name>
```

## Security

This project has **not been professionally audited**. It's provided as-is for educational and experimental purposes. Do not deploy it to mainnet with real funds without an independent security review, and never reuse any keys or mnemonics from local development or testnets for a wallet that holds real assets.

## License

[MIT](LICENSE)
