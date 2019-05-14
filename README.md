<img src="https://augurlite.com/static/logo.png" width="300px" />

**Welcome to AugurLite!** AugurLite is a decentralized prediction market protocol, built on Ethereum. The protocol is a fork of Augur v1, whose code is available [here](https://github.com/AugurProject/augur-core). AugurLite shares much of the same functionality as Augur but is designed to be more modular—supporting multiple denomination tokens and oracle systems.

## Introduction
AugurLite is a protocol for creating and resolving prediction market contracts on Ethereum. Each prediction market is a smart contract with a chosen denomination token, such as [Dai](https://makerdao.com/dai/). Denomination tokens can be escrowed in the market in exchange for a set of outcome tokens, each of which is an [ERC-20 token](https://en.wikipedia.org/wiki/ERC-20). The outcome tokens can be traded or exchanged on platforms like [Veil](https://veil.co), and ultimately redeemed for a portion of the escrowed denomination tokens.

The best way of explaining the AugurLite concepts may be discussing each smart contract that is part of the protocol. Here is a breakdown.

## AugurLite Contracts

#### AugurLite [Go to code](https://github.com/veilco/augur-lite/blob/master/source/contracts/AugurLite.sol)
This is the protocol's master contract. It is responsible for logging protocol-wide events, controlling transfers of denomination tokens, and creating the genesis universe using the UniverseFactory. This contract is a fork of Augur's [main contract](https://github.com/AugurProject/augur-core/blob/master/source/contracts/Augur.sol).

#### Universe [Go to code](https://github.com/veilco/augur-lite/blob/master/source/contracts/reporting/Universe.sol)
Conceptually, a universe is a container for markets that use the same denomination token. Each universe is created by the AugurLite contract. New markets (scalar, yesno, categorical) are created by calling this contract that in turn uses MarketFactory contracts. The Universe contract stores the denomination token that is used for all markets created in the universe. Unlike [Augur's equivalent](https://github.com/AugurProject/augur-core/blob/master/source/contracts/reporting/Universe.sol), this contract doesn't have any concept of forking, fee windows, reporting fees, open interest, or REP, because AugurLite does not come with an oracle out-of-the-box.

#### Market [Go to code](https://github.com/veilco/augur-lite/blob/master/source/contracts/reporting/Market.sol)
A market is effectively a question about the future. Examples might be "Will Kamala Harris win the 2020 Democratic presidential nomination?" or "What will be the price of Bitcoin (BTC) in USD at 5pm PDT on Friday, May 17, 2019?" Markets come in three types: yes/no, categorical, and scalar.

AugurLite markets have an `oracle` field which specifies which Ethereum address can resolve the market, meaning specify how much each outcome is actually worth on expiration. All markets in Augur by default use the Augur oracle for resolution, and therefore users are required to deposit ETH and REP when creating a market. AugurLite is oracle-agnostic, so markets could be resolved by referencing the result of an Augur market or some other piece of Ethereum state. Therefore, users do not have to pay additional ETH, REP, or any other currency when creating markets.

This contract shares many of the same fields as Augur's [Market contract](https://github.com/AugurProject/augur-core/blob/master/source/contracts/reporting/Market.sol). It's worth noting that the initial reporter and reporting participants concepts have been removed because they relate to the Augur oracle, which is irrelevant here. Markets are resolved by calling one `resolve` method. There is no finalization process as there is on Augur.

Upon market creation, a market creator mailbox is created through the MailboxFactory, and share tokens are created through the ShareTokenFactory. We'll talk more about those in their own sections below. Markets also have a market creator fee that is charged when shares are redeemed. 

#### ShareToken [Go to code](https://github.com/veilco/augur-lite/blob/master/source/contracts/trading/ShareToken.sol)
These are mintable, burnable ERC-20 tokens that represent outcomes in markets. They are created by ShareTokenFactory. A share token should be valued between 0 and 1 of the relevant denomination token. For instance, if you own a "YES" share token in a market denominated in Dai about an event that ends up happening, that share token will be worth 1 DAI upon resolution. Similarly, the "NO" share token in that market will be worth 0 DAI. There is an equivalent [ShareToken contract](https://github.com/AugurProject/augur-core/blob/master/source/contracts/trading/ShareToken.sol) in Augur.

#### CompleteSets [Go to code](https://github.com/veilco/augur-lite/blob/master/source/contracts/trading/CompleteSets.sol)
A complete set is a basket of all share tokens in a market. For instance, 1 complete set in a yes/no market would be 1 "YES" share token and 1 "NO" share token. Complete sets have the property of always being worth denomination token, because regardless of the outcome of the market, the sum of the values of the share tokens will be 1. This contract lets uesrs buy and sell complete sets in a given market. A user can buy a complete set by escrowing 1 denomination token in the market in exchange for 1 complete set. And a user can sell a complete set by exchanging the set for 1 denomination token (minus the market creator fee) that had been escrowed in the market. There is an equivalent [CompleteSets contract](https://github.com/AugurProject/augur-core/blob/master/source/contracts/trading/CompleteSets.sol) in Augur.

#### ClaimTradingProceeds [Go to code](https://github.com/veilco/augur-lite/blob/master/source/contracts/trading/ClaimTradingProceeds.sol)
This contract lets users exchange their share tokens for denomination tokens once a market resolves. It is equivalent to the [ClaimTradingProceeds contract](https://github.com/AugurProject/augur-core/blob/master/source/contracts/trading/ClaimTradingProceeds.sol) in Augur.

You will notice that all other trading-related contracts from Augur do not exist in AugurLite. That is because AugurLite defers trading to other off-chain exchange protocols (like [0x](https://0x.org/) or [Hydro](https://hydroprotocol.io/)) and encourages users to trade through off-chain relayers (like [Veil](https://veil.co/), [BlitzPredict](https://www.blitzpredict.io/), or [Flux](https://flux.market/)) for better performance.

#### Mailbox [Go to code](https://github.com/veilco/augur-lite/blob/master/source/contracts/reporting/Mailbox.sol)
This contract is deployed per market and is owned by the market creator. It collects the market creator fees, and it's ownership can be transferred. There is an equivalent [Mailbox contract](https://github.com/AugurProject/augur-core/blob/master/source/contracts/reporting/Mailbox.sol) in Augur.

#### Factory Contracts: MailboxFactory, MarketFactory, ShareTokenFactory, UniverseFactory
AugurLite uses UniverseFactory to create the genesis universe. The Universe contract uses MarketFactory to create new markets. Upon deployment, market contracts use MailboxFactory to create the market creator mailbox, and ShareTokenFactory to create outcome tokens.

## Comparison
|                       | <img src="https://statrader.com/wp-content/uploads/2018/05/Augur-Logo.png" height="100px" />|<img src="https://augurlite.com/static/logo.png" height="100px" />|
|-----------------------|----------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Market creation**       | ✅ Anyone can create a market, but they must deposit ETH and REP to do so.                                               | ✅ Anyone can create a market, and there is no fee or deposit for doing so.                                                                                                           |
| **Complete sets**         | ✅ Complete sets of ERC20 outcome tokens can be created by escrowing ETH. Complete sets can also be settled at any time. | ✅ Complete sets of ERC20 outcome tokens can be created by escrowing whatever the denomination token of the universe is (default Dai). Complete sets can also be settled at any time. |
| **Trading and liquidity** | ✅ Orders are created and maintained on-chain. A custom order matching engine matches and executes trades.               | 🚫 No trading happens through the protocol. The ERC20 outcome tokens should be traded on other protocols like 0x or Hydro. Relayers like Veil, BlitzPredict, or Flux can provide UX.   |
| **Oracle**                | ✅ Users stake REP tokens on a weekly cadence to determine the outcome of markets.                                       | 🚫 No oracle is built into the protocol. Instead, markets have a resolver which can reference any oracle—an Augur market, Chainlink feed, or any arbitrary smart contract state.       |
| **Settlement**            | ✅ Once the oracle report is finalized, users can redeem their outcome tokens for their portion of the escrowed ETH.     | ✅ Once the market is resolved, users can redeem their outcome tokens for their portion of the escrowed currency.                                                                     |

## High-level Changes

-   AugurLite removes all on-chain trading logic. AugurLite simply acts as an escrow layer, converting money into transferable share tokens and back.
    -   As part of this change, all trading contracts except `ClaimTradingProceeds` and `CompleteSets` have been removed.
    -   Because there is no on-chain trading, controller contracts like `TradingEscapeHatch` has been removed.
-   AugurLite is oracle agnostic. That means there is no reporting or dispute process at the base protocol. During market creation, an “oracle” address is specified. This “oracle” can resolve a market upon expiration, and the result is final. Without a reporting/dispute process:
    -   There’s no need for a native token (ie REP in Augur).
    -   There’s no need for a concept like `ReportingParticipants` or `DisputeCrowdsourcers`. There is a single address (“oracle”), that can resolve markets (with a single “resolve” call), and all the resolution details are stored on the market.
    -   There are no reporting fees. This means creating markets on AugurLite does not require validity or no-show bonds, and is much cheaper. Users only pay market creator fees that are deducted when users sell complete sets or claim trading proceeds.
    -   There are no fee windows or fee tokens. The single “oracle” address has the final say on the resolution of the market.
    -   There’s no concept of forking. There’s a single genesis universe which contains all markets and all share tokens. This universe keeps track of open interest across markets.
-   AugurLite markets can you use any ERC-20 compliant token as denomination tokens, not just CASH. Unlike Augur, the denomination token is specified at the Universe level. What this means is, every market created within a Universe will have the same denomination token. Following this change, all the open interest tracking at the Universe level is removed.
-   Augur contracts were written in Solidity version 0.4.20. AugurLite contracts are updated to use the most recent stable version of version 0.4.xx: 0.4.26.
-   Following all the changes above, the deployment and testing scripts are much simpler and more streamlined.

While the origin Augur V1 codebase is massive, the main changes were made to following 5 contracts:

-   source/contracts/reporting/Mailbox.sol
-   source/contracts/reporting/Market.sol
-   source/contracts/reporting/Universe.sol
-   source/contracts/trading/ClaimTradingProceeds.sol
-   source/contracts/trading/CompleteSets.sol

If you're looking for a more in-depth list of changes, please check the [CHANGELOG](https://github.com/veilco/augur-lite/CHANGELOG.md) filed.

## Installation

You need system-wide installations of Python 3.7.3, Node.js 10.12, and [Solidity 0.4.26](https://github.com/ethereum/solidity/releases/tag/v0.4.26). On MacOS, you also need to use [venv](https://packaging.python.org/guides/installing-using-pip-and-virtual-environments/) for package management.

To setup venv:

```bash
python3 -m venv venv # Creates venv directory to install Python packages
source venv/bin/activate # Activates the virtual environment
```

You can switch away from your environment with:

```bash
deactivate
```

Once your Python setup is complete, install the dependencies:

```bash
yarn add npx
yarn
pip install -r requirements.txt
```

If you're planning to deploy contracts, create an `.env` in the base directory. Depending on the network you're trying to deploy to, set the necessary environment variables. For more information on environment variables, you need, see `NetworkConfiguration` file. As an example, for a Kovan deployment, the following `.env` file should suffice:

```
KOVAN_ETHEREUM_HTTP=...
KOVAN_PRIVATE_KEY=...
```

Now, you should be able to compile contracts, build contract interfaces, and deploy contracts. Follow the instructions in the next section.

## Deployment

Solidity contract deployment is handled by `ContractDeployer.ts` and the wrapper programs located in `source/deployment`. This deployment framework allows for incremental deploys of contracts to a given controller (specified via a configuration option). This allows us to deploy new contracts without touching the controller, effectively upgrading the deployed system in-place.

-   Main Code

    -   source/libraries/ContractCompiler.ts - All logic for compiling contracts, generating ABI
    -   source/libraries/ContractDeployer.ts - All logic for uploading, initializing, and whitelisting contracts, generating addresses and block number outputs.

-   Configuration

    -   source/libraries/CompilerConfiguration.ts
    -   source/libraries/DeployerConfiguration.ts
    -   source/libraries/NetworkConfiguration.ts

Overall, it's best to use helper functionality as defined in `package.json`. As an example, upon environment setup, you can deploy contracts to your desired network by:

```bash
yarn run build # Compiles contracts and builds contract interfaces
yarn run deploy:kovan # Deploys contracts to Kovan
```

## Smart contract organization

Solidity smart contracts reside in `source/contracts`. Specifically:

-   `source/contracts/factories`: Constructors for universes, markets, share tokens etc.
-   `source/contracts/libraries`: Libraries (ie SafeMath) or utility contracts (ie MarketValidator) used elsewhere in the source code.
-   `source/contracts/reporting`: Contracts for managing universes and creating/managing markets.
-   `source/contracts/trading`: Contracts to issue and close out complete sets of shares, and for traders to claim proceeds after markets are resolved.

## TODOs

-   Simplify the smart contract folder structure. `reporting`/`trading` distinction doesn't make sense anymore
-   Possibly remove denomination token from markets, and only use the universe denomination token. Currently, denomination token is redundantly stored.
-   Update tests to take new Universe initialization into account
