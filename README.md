# augur-lite

This repo is a fork of the Augur V1 contract code, available [here](https://github.com/AugurProject/augur-core).

## Contracts

**AugurLite:** Similar to Augur's version, this contract is responsible for logging protocol-wide events, controlling transfers of denomination tokens, and creating the genesis universe using the UniverseFactory. The contract doesn't have any of the forking functionality for the universes.

**Universe:** Created by the AugurLite contract. Conceptually, it's a container for markets. New markets (scalar, yesno, categorical) are created by calling this contract that in turn uses MarketFactory contracts. The Universe contract stores the denomination token that'll be used for the markets created in the universe. This contract doesn't have any concept of forking, fee windows, reporting fees, open interest, REP etc.

**Market:** Specifies market details. It's a simplified version of Augur's market contract (ie most fields are the same). Upon market creation, a market creator mailbox is created through the MailboxFactory, and share tokens are created through the ShareTokenFactory. Market creator mailbox is used to collect market creator fees. The concepts of initial reporter and reporting participants are removed, as there is a single oracle address. The market reporting and finalization process is simplified to a single resolve method. The market denomination token can only be the Universe denomination token. TODO: Maybe don't store the denomination token on the market.

**ShareToken:** Mintable/burnable ERC-20 token that represents outcomes in markets. Created by ShareTokenFactory.

**CompleteSets:** Contract that lets anyone buy and sell complete sets in a given market. 1 complete set consists of 1 of each share token in the market. 1 denomination token (ie DAI) buys 1 complete set. Selling a complete set returns the 1 denomination token (minus the market creator fee).

**ClaimTradingProceeds:** Contract that lets anyone exchange their shares for market's denomination token.

**Mailbox:** This contract is deployed per market and is owned by the market creator. It collects the market creator fees, and it's ownership can be transferred.

**Factory Contracts:** MailboxFactory, MarketFactory, ShareTokenFactory, UniverseFactory. VeilAugur contract uses UniverseFactory to create the genesis universe. Universe contract uses MarketFactory to create new markets. Upon deployment, market contracts use MailboxFactory to create the market creator mailbox, and ShareTokenFactory to create outcome tokens.

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
yarn install npx
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
-   Simplify the deployment scripts. Possibly use `truffle`
-   Deploy the repo to NPM as `augur-lite`
-   Possibly remove denomination token from markets, and only use the universe denomination token. Currently, denomination token is redundantly stored.
-   Update tests to take new Universe initialization into account
