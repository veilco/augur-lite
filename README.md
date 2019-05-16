<img src="https://augurlite.com/static/logo.png" width="300px" />

**Welcome to AugurLite!** AugurLite is a decentralized prediction market protocol, built on Ethereum. The protocol is a fork of Augur v1, whose code is available [here](https://github.com/AugurProject/augur-core). AugurLite shares much of the same functionality as Augur but is designed to be more modular—supporting multiple denomination tokens and oracle systems.

## Introduction

AugurLite is a protocol for creating and resolving prediction market contracts on Ethereum. Each prediction market is a smart contract with a chosen denomination token, such as [Dai](https://makerdao.com/dai/). Denomination tokens can be escrowed in a market in exchange for a set of outcome tokens, each of which is an [ERC-20 token](https://en.wikipedia.org/wiki/ERC-20). The outcome tokens can be traded or exchanged on platforms like [Veil](https://veil.co), and ultimately redeemed for a portion of the escrowed denomination tokens once the chosen oracle resolves the market.

## Overview

To explain AugurLite concepts, we will discuss each smart contract that makes up the protocol. Here is the breakdown.

#### AugurLite [`Go to code`](/source/contracts/AugurLite.sol)

This is the protocol's master contract. It is responsible for logging protocol-wide events, controlling transfers of denomination tokens, and creating the genesis universe using the UniverseFactory. This contract is a fork of Augur's [main contract](https://github.com/AugurProject/augur-core/blob/master/source/contracts/Augur.sol).

#### Universe [`Go to code`](/source/contracts/Universe.sol)

Conceptually, a universe is a container for markets that use the same denomination token. Each universe is created by the AugurLite contract. New markets (scalar, yesno, categorical) are created by calling this contract that in turn uses MarketFactory contracts. The Universe contract stores the denomination token that is used for all markets created in the universe. Unlike [Augur's equivalent](https://github.com/AugurProject/augur-core/blob/master/source/contracts/reporting/Universe.sol), this contract doesn't have any concept of forking, fee windows, reporting fees, open interest, or REP, because AugurLite does not come with an oracle out-of-the-box.

#### Market [`Go to code`](/source/contracts/Market.sol)

A market is effectively a question about the future. Examples might be "Will Kamala Harris win the 2020 Democratic presidential nomination?" or "What will be the price of Bitcoin (BTC) in USD at 5pm PDT on Friday, May 17, 2019?" Markets come in three types: yes/no, categorical, and scalar.

AugurLite markets have an `oracle` field which specifies which Ethereum address can resolve the market, meaning specify how much each outcome is actually worth on expiration. All markets in Augur by default use the Augur oracle for resolution, and therefore users are required to deposit ETH and REP when creating a market. AugurLite is oracle-agnostic, so markets could be resolved by referencing the result of an Augur market or some other piece of Ethereum state. Therefore, users do not have to pay additional ETH, REP, or any other currency when creating markets.

This contract shares many of the same fields as Augur's [Market contract](https://github.com/AugurProject/augur-core/blob/master/source/contracts/Market.sol). It's worth noting that the initial reporter and reporting participants concepts have been removed because they relate to the Augur oracle, which is irrelevant here. Markets are resolved by calling one `resolve` method. There is no finalization process as there is on Augur.

Upon market creation, a market creator mailbox is created through the MailboxFactory, and share tokens are created through the ShareTokenFactory. We'll talk more about those in their own sections below. Markets also have a market creator fee that is charged when shares are redeemed.

#### ShareToken [`Go to code`](/source/contracts/ShareToken.sol)

These are mintable, burnable ERC-20 tokens that represent outcomes in markets. They are created by ShareTokenFactory. A share token should be valued between 0 and 1 of the relevant denomination token. For instance, if you own a "YES" share token in a market denominated in Dai about an event that ends up happening, that share token will be worth 1 DAI upon resolution. Similarly, the "NO" share token in that market will be worth 0 DAI. There is an equivalent [ShareToken contract](https://github.com/AugurProject/augur-core/blob/master/source/contracts/trading/ShareToken.sol) in Augur.

#### CompleteSets [`Go to code`](/source/contracts/CompleteSets.sol)

A complete set is a basket of all share tokens in a market. For instance, 1 complete set in a yes/no market would be 1 "YES" share token and 1 "NO" share token. Complete sets have the property of always being worth denomination token, because regardless of the outcome of the market, the sum of the values of the share tokens will be 1. This contract lets users buy and sell complete sets in a given market. A user can buy a complete set by escrowing 1 denomination token in the market in exchange for 1 complete set. And a user can sell a complete set by exchanging the set for 1 denomination token (minus the market creator fee) that had been escrowed in the market. There is an equivalent [CompleteSets contract](https://github.com/AugurProject/augur-core/blob/master/source/contracts/trading/CompleteSets.sol) in Augur.

#### ClaimTradingProceeds [`Go to code`](/source/contracts/ClaimTradingProceeds.sol)

This contract lets users exchange their share tokens for denomination tokens once a market resolves. It is equivalent to the [ClaimTradingProceeds contract](https://github.com/AugurProject/augur-core/blob/master/source/contracts/trading/ClaimTradingProceeds.sol) in Augur.

You will notice that all other trading-related contracts from Augur do not exist in AugurLite. That is because AugurLite defers trading to other off-chain exchange protocols (like [0x](https://0x.org/) or [Hydro](https://hydroprotocol.io/)) and encourages users to trade through off-chain relayers (like [Veil](https://veil.co/), [BlitzPredict](https://www.blitzpredict.io/), or [Flux](https://flux.market/)) for better performance.

#### Mailbox [`Go to code`](/source/contracts/Mailbox.sol)

This contract is deployed per market and is owned by the market creator. It collects the market creator fees, and it's ownership can be transferred. There is an equivalent [Mailbox contract](https://github.com/AugurProject/augur-core/blob/master/source/contracts/reporting/Mailbox.sol) in Augur.

#### Factory Contracts [`Go to code`](source/contracts/factories)

AugurLite uses the [`UniverseFactory`](/source/contracts/factories/UniverseFactory.sol) contract to create universes, including the genesis universe. Universe contracts uses [`MarketFactory`](/source/contracts/factories/MarketFactory.sol) to create new markets. Upon deployment, market contracts use [`MailboxFactory`](/source/contracts/factories/MailboxFactory.sol) to create mailboxes for the market creators and [`ShareTokenFactory`](/source/contracts/factories/ShareTokenFactory.sol) to create outcome tokens (i.e. share tokens).

## Comparison

Here is a table that highlights the main differences between Augur and AugurLite.

|                           | <img src="https://statrader.com/wp-content/uploads/2018/05/Augur-Logo.png" height="100px" />                             | <img src="https://augurlite.com/static/logo.png" height="100px" />                                                                                                                    |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Market creation**       | ✅ Anyone can create a market, but they must deposit ETH and REP to do so.                                               | ✅ Anyone can create a market, and there is no fee or deposit for doing so.                                                                                                           |
| **Denomination tokens**   | 🚫 Markets are only collateralized in ETH.                                                                               | ✅ Markets are collateralized in any arbitrary ERC-20 token.                                                                                                                          |
| **Complete sets**         | ✅ Complete sets of ERC20 outcome tokens can be created by escrowing ETH. Complete sets can also be settled at any time. | ✅ Complete sets of ERC20 outcome tokens can be created by escrowing whatever the denomination token of the universe is (default Dai). Complete sets can also be settled at any time. |
| **Trading and liquidity** | ✅ Orders are created and maintained on-chain. A custom order matching engine matches and executes trades.               | 🚫 No trading happens through the protocol. The ERC20 outcome tokens should be traded on other protocols like 0x or Hydro. Relayers like Veil, BlitzPredict, or Flux can provide UX.  |
| **Oracle**                | ✅ Users stake REP tokens on a weekly cadence to determine the outcome of markets.                                       | 🚫 No oracle is built into the protocol. Instead, markets have a resolver which can reference any oracle—an Augur market, Chainlink feed, or any arbitrary smart contract state.      |
| **Settlement**            | ✅ Once the oracle report is finalized, users can redeem their outcome tokens for their portion of the escrowed ETH.     | ✅ Once the market is resolved, users can redeem their outcome tokens for their portion of the escrowed currency.                                                                     |

If you're looking for a more in-depth list of changes, please review the [CHANGELOG](/CHANGELOG.md) file.

#### Current addresses of relevant contracts

| Contract                                                                 | Commit                                                                                           | Ethereum Address                                                                                                      |
| ------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------- |
| [`AugurLite`](/source/contracts/AugurLite.sol)                           | [c9c0817cd1](https://github.com/veilco/augur-lite/tree/c9c0817cd196c554bc4bc6496561ec499f7dde78) | [0x5c025873f7aee04719b6c13fe453b5e446c7ed05](https://etherscan.io/address/0x5c025873f7aee04719b6c13fe453b5e446c7ed05) |
| [`ClaimTradingProceeds`](/source/contracts/ClaimTradingProceeds.sol)     | [c9c0817cd1](https://github.com/veilco/augur-lite/tree/c9c0817cd196c554bc4bc6496561ec499f7dde78) | [0x32cfb05a69328ac6a2944fc35c48ecb9a448c31d](https://etherscan.io/address/0x32cfb05a69328ac6a2944fc35c48ecb9a448c31d) |
| [`CompleteSets`](/source/contracts/CompleteSets.sol)                     | [c9c0817cd1](https://github.com/veilco/augur-lite/tree/c9c0817cd196c554bc4bc6496561ec499f7dde78) | [0x92e320330007aa538b0315297c2299fd746d6d8d](https://etherscan.io/address/0x92e320330007aa538b0315297c2299fd746d6d8d) |
| [`Controller`](/source/contracts/Controller.sol)                         | [c9c0817cd1](https://github.com/veilco/augur-lite/tree/c9c0817cd196c554bc4bc6496561ec499f7dde78) | [0x23d27cc545503a6a1b7127c1a1a2777a38a2aa17](https://etherscan.io/address/0x23d27cc545503a6a1b7127c1a1a2777a38a2aa17) |
| [`DAIUniverse`](/source/contracts/Universe.sol)                          | [c9c0817cd1](https://github.com/veilco/augur-lite/tree/c9c0817cd196c554bc4bc6496561ec499f7dde78) | [0xba38540b0f2e11b3ac839b65756bcd8501ded215](https://etherscan.io/address/0xba38540b0f2e11b3ac839b65756bcd8501ded215) |
| [`MailboxFactory`](/source/contracts/factories/MailboxFactory.sol)       | [c9c0817cd1](https://github.com/veilco/augur-lite/tree/c9c0817cd196c554bc4bc6496561ec499f7dde78) | [0x1e86d8a1c4287e4ea8566e42e02375b5a4caac44](https://etherscan.io/address/0x1e86d8a1c4287e4ea8566e42e02375b5a4caac44) |
| [`MarketFactory`](/source/contracts/factories/MarketFactory.sol)         | [c9c0817cd1](https://github.com/veilco/augur-lite/tree/c9c0817cd196c554bc4bc6496561ec499f7dde78) | [0x2f5ef0fa22a008b1054a9a7f9b2c6e545ccf3873](https://etherscan.io/address/0x2f5ef0fa22a008b1054a9a7f9b2c6e545ccf3873) |
| [`ShareTokenFactory`](/source/contracts/factories/ShareTokenFactory.sol) | [c9c0817cd1](https://github.com/veilco/augur-lite/tree/c9c0817cd196c554bc4bc6496561ec499f7dde78) | [0x739b21035799702474da538c3ed22c72415e5f5e](https://etherscan.io/address/0x739b21035799702474da538c3ed22c72415e5f5e) |
| [`UniverseFactory`](/source/contracts/factories/UniverseFactory.sol)     | [c9c0817cd1](https://github.com/veilco/augur-lite/tree/c9c0817cd196c554bc4bc6496561ec499f7dde78) | [0xb08ff5e8484c96d5db9b5fb157bcd3df81501ebb](https://etherscan.io/address/0xb08ff5e8484c96d5db9b5fb157bcd3df81501ebb) |
| [`Time`](/source/contracts/Time.sol)                                     | [c9c0817cd1](https://github.com/veilco/augur-lite/tree/c9c0817cd196c554bc4bc6496561ec499f7dde78) | [0x8bc8a395671c1c200a56e4a7fd3fc74ee2620522](https://etherscan.io/address/0x8bc8a395671c1c200a56e4a7fd3fc74ee2620522) |

## Installation

You need system-wide installations of [Python 3.7.3](https://www.python.org/downloads/release/python-373/), [Node.js 10.12](https://nodejs.org/en/blog/release/v10.12.0/), and [Solidity 0.4.26](https://github.com/ethereum/solidity/releases/tag/v0.4.26). On MacOS, you also need to use [venv](https://packaging.python.org/guides/installing-using-pip-and-virtual-environments/) for package management.

Setting up a specific `solc` version could get tricky. We recommend using [Homebrew](https://github.com/ethereum/homebrew-ethereum/blob/master/solidity.rb), and following [this guide](https://gist.github.com/zulhfreelancer/26daf8c04569d1cd98841ef8a4e8d948) to help install the latest `0.4.xx` version of Solidity.

To setup venv:

```bash
python3 -m venv venv # Creates venv directory to install Python packages
source venv/bin/activate # Activates the virtual environment
```

You can switch away from your environment with:

```bash
deactivate
```

Once your Python setup is complete, install JS dependencies with [yarn](https://yarnpkg.com/en/):

```bash
yarn add npx
yarn
```

## Deployment

To deploy the contracts, you need to create an `.env` in the base directory. The specification for the `.env` file will depend on which Ethereum network you are deploying to. Review the [NetworkConfiguration file](/source/libraries/NetworkConfiguration.ts) to see all options. Or copy one of the examples below for common networks.

Sample `.env` file for Kovan:

```
KOVAN_ETHEREUM_HTTP=https://eth-kovan.alchemyapi.io/jsonrpc/<INSERT API KEY>
KOVAN_PRIVATE_KEY=<INSERT PRIVATE KEY OF ADDRESS DEPLOYING CONTRACTS>
```

Sample `.env` file for Mainnet:

```
MAINNET_ETHEREUM_HTTP=https://eth-mainnet.alchemyapi.io/jsonrpc/<INSERT API KEY>
MAINNET_PRIVATE_KEY=<INSERT PRIVATE KEY OF ADDRESS DEPLOYING CONTRACTS>
```

Now you should be able to compile contracts, build contract interfaces, and deploy contracts.

```bash
yarn run build              # Compiles contracts and builds contract interfaces
yarn run deploy:kovan       # Deploys contracts to Kovan
yarn run deploy:mainnet     # Deploys contracts to Mainnet
```

You can see a full list of helper functions to run with `yarn` in [package.json](/package.json).

Solidity contract deployment is handled by [`ContractDeployer.ts`](/source/libraries/ContractDeployer.ts) and the wrapper programs located in [`source/deployment`](/source/deployment). This deployment framework allows for incremental deploys of contracts to a given controller (specified via a configuration option). This allows us to deploy new contracts without touching the controller, effectively upgrading the deployed system in-place.

#### Main Code

-   [`source/libraries/ContractCompiler.ts`](/source/libraries/ContractCompiler.ts) - All logic for compiling contracts, generating ABI
-   [`source/libraries/ContractDeployer.ts`](/source/libraries/ContractDeployer.ts) - All logic for uploading, initializing, and whitelisting contracts, generating addresses and block number outputs.

#### Configuration

-   [`source/libraries/CompilerConfiguration.ts`](/source/libraries/CompilerConfiguration.ts)
-   [`source/libraries/DeployerConfiguration.ts`](/source/libraries/DeployerConfiguration.ts)
-   [`source/libraries/NetworkConfiguration.ts`](/source/libraries/NetworkConfiguration.ts)

## Smart contract organization

Solidity smart contracts reside in [`source/contracts`](/source/contracts). There are two additional folders:

-   [`source/contracts/factories`](/source/contracts/factories): Constructors for universes, markets, share tokens etc.
-   [`source/contracts/libraries`](/source/contracts/libraries): Libraries (like `SafeMath`) or utility contracts (like `MarketValidator`) used elsewhere in the source code.

## Oracles and custom resolvers

By design, AugurLite does not come packaged with an oracle system. An oracle is some sort of mechanism for bringing information from the real-world onto a blockchain, enabling smart contracts to respond to it. Here are some popular oracle systems:

-   [Augur](http://augur.net/)
-   [Chainlink](https://chain.link/)
-   [Verity](https://verity.network/)
-   [Witnet](https://witnet.io)
-   [Polaris](https://medium.com/marbleorg/introducing-polaris-ced195dd798e)

One goal of AugurLite is to decouple markets from their oracles. Not every market needs to be reviewed by the Augur reporting community. And an oracle for data feeds should be designed differently from an oracle for one-off events. Therefore, markets in AugurLite simply designate an Ethereum address that has the power to resolve them. That oracle address could be a trusted third-party, a smart contract that can observe state from an oracle and pass it along to AugurLite, or something else entirely.

#### Example: OracleBridge

As an example, Veil uses a smart contract called [`OracleBridge`](https://github.com/veilco/veil-contracts/blob/master/contracts/OracleBridge.sol) to observe the result of Augur markets and resolve AugurLite markets accordingly. The `OracleBridge` address is set as the oracle for [Veil's 2020 US Presidential Election markets](https://veil.co/2020) in order to abstract away various oracle systems. Read more in [Veil's smart contracts repository](https://github.com/veilco/veil-contracts).

## Additional resources

Here is a short collection of resources and guides to better understand the Augur ecosystem:

-   [Augur.Guide](https://augur.guide/)
-   [A guide to Augur market economics](https://medium.com/veil-blog/a-guide-to-augur-market-economics-16c66d956b6c)
-   [Off-chain trading with Augur and 0x](https://medium.com/veil-blog/off-chain-trading-with-augur-and-0x-e2f0c05db3bd)

## Questions and support

If you have questions, comments, or ideas, we recommend pursuing one of these channels:

-   Open an issue or pull request in this repository
-   Reach out to [@veil on Twitter](https://twitter.com/veil)
-   Send an email to [hello@veil.co](mailto:hello@veil.co)
-   Join [Veil's discord](https://discord.gg/aBfTCVU) and reach out to a Veil team member

## License

AugurLite is released under the GNU General Public License v3.0. [See License](/LICENSE).
