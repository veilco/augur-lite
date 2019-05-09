# augur-lite

**_This repo is a fork of the Augur V1 contract code, available [here](https://github.com/AugurProject/augur-core)._**

## Contracts

**AugurLite:** Similar to Augur's version, this contract is responsible for logging protocol-wide events, controlling transfers of denomination tokens (most commonly DAI), and creating the genesis universe using the UniverseFactory. The contract doesn't have any of the forking functionality for the universes.

**Universe:** Created by the AugurLite contract. Conceptually, it's a container for markets. New markets (scalar, yesno, categorical) are created by calling this contract that in turn uses MarketFactory contracts. The Universe contract also keeps track of open interest across all markets. This contract doesn't have any concept of forking, fee windows, reporting fees, REP etc.

**Market:** Specifies market details. It's a simplified version of Augur's market contract (ie most fields are the same). Upon market creation, a market creator mailbox is created through the MailboxFactory, and share tokens are created through the ShareTokenFactory. Market creator mailbox is used to collect market creator fees. The concepts of initial reporter and reporting participants are removed, as there is a single oracle address. The market reporting and finalization process is simplified to a single resolve method. The market denomination token is not hard-coded to be CASH, but can be any ERC-20 compliant token (ie DAI).

**ShareToken:** Mintable/burnable ERC-20 token that represents outcomes in markets. Created by ShareTokenFactory.

**CompleteSets:** Contract that lets anyone buy and sell complete sets in a given market. 1 complete set consists of 1 of each share token in the market. 1 denomination token (ie DAI) buys 1 complete set. Selling a complete set returns the 1 denomination token (minus the market creator fee).

**ClaimTradingProceeds:** Contract that lets anyone exchange their shares for market's denomination token.

**Mailbox:** This contract is deployed per market and is owned by the market creator. It collects the market creator fees, and it's ownership can be transferred.

**Factory Contracts:** MailboxFactory, MarketFactory, ShareTokenFactory, UniverseFactory. VeilAugur contract uses UniverseFactory to create the genesis universe. Universe contract uses MarketFactory to create new markets. Upon deployment, market contracts use MailboxFactory to create the market creator mailbox, and ShareTokenFactory to create outcome tokens.

## High-level Changes

-   AugurLite removes all on-chain trading logic. AugurLite simply acts as an escrow layer, converting money into transferable share tokens and back.
    -   As part of this change, all trading contracts except ClaimTradingProceeds and CompleteSets have been removed.
    -   Because there is no on-chain trading, controller contracts like TradingEscapeHatch has been removed.
-   AugurLite is oracle agnostic. That means there is no reporting or dispute process at the base protocol. During market creation, an “oracle” address is specified. This “oracle” can resolve a market upon expiration, and the result is final. Without a reporting/dispute process:
    -   There’s no need for a native token (ie REP in Augur).
    -   There’s no need for a concept like ReportingParticipants or DisputeCrowdsourcers. There is a single address (“oracle”), that can resolve markets (with a single “resolve” call), and all the resolution details are stored on the market.
    -   There are no reporting fees. This means creating markets on AugurLite does not require validity or no-show bonds, and is much cheaper. Users only pay market creator fees that are deducted when users sell complete sets or claim trading proceeds.
    -   There are no fee windows or fee tokens. The single “oracle” address has the final say on the resolution of the market.
    -   There’s no concept of forking. There’s a single genesis universe which contains all markets and all share tokens. This universe keeps track of open interest across markets.
-   AugurLite markets can you use any ERC-20 compliant token as denomination tokens, not just CASH. NOTE: This will change to only allow a single currency.
    -   Veil will support markets denominated in DAI.
-   Augur contracts were written in Solidity version 0.4.20. AugurLite contracts are updated to use the most recent stable version of version 0.4.xx: 0.4.26.
-   Following all the changes above, the deployment and testing scripts are much simpler and more streamlined.

While the origin Augur V1 codebase is massive, the main changes were made to following 5 contracts:

-   source/contracts/reporting/Mailbox.sol
-   source/contracts/reporting/Market.sol
-   source/contracts/reporting/Universe.sol
-   source/contracts/trading/ClaimTradingProceeds.sol
-   source/contracts/trading/CompleteSets.sol

## Installation

You need system-wide installations of Python 3.7.3, Node.js 10.12, and [Solidity 0.4.26](https://github.com/ethereum/solidity/releases/tag/v0.4.26). On MacOS, you also need to use [venv](https://packaging.python.org/guides/installing-using-pip-and-virtual-environments/) for package management.

To setup venv:

```bash
python3 -m venv venv # Creates venv directory to install Python packages
source venv/bin/activate # Activates the virtual environment
```

Once your Python setup is complete, install the dependencies:

```bash
yarn install npx
yarn
pip install -r requirements.txt
```

Now, you should be able to compile contracts, build contract interfaces, and deploy contracts with:

```bash
yarn run build # Compiles contracts and builds contract interfaces
yarn run deploy:kovan # Deploys contracts to Kovan
```

## Deployment

Solidity contract deployment is handled by `ContractDeployer.ts` and the wrapper programs located in `source/deployment`. This deployment framework allows for incremental deploys of contracts to a given controller (specified via a configuration option). This allows us to deploy new contracts without touching the controller, effectively upgrading the deployed system in-place.

-   Main Code

    -   source/libraries/ContractCompiler.ts - All logic for compiling contracts, generating ABI
    -   source/libraries/ContractDeployer.ts - All logic for uploading, initializing, and whitelisting contracts, generating addresses and block number outputs.

-   Configuration

    -   source/libraries/CompilerConfiguration.ts
    -   source/libraries/DeployerConfiguration.ts
    -   source/libraries/NetworkConfiguration.ts -

-   Wrapper programs
    -   source/deployment/compileAndDeploy.ts - Compiles and Uploads contracts in one step. Useful for integration testing.
    -   source/deployment/compiledContracts.ts - Compile contract source (from source/contracts) and output contracts.json and abi.json. Outputs to output/contracts or CONTRACTS_OUTPUT_ROOT if defined.
    -   source/deployment/deployNetworks.ts - Application that can upload / upgrade all contracts, reads contracts from CONTRACTS_OUTPUT_ROOT, and uses a named network configuration to connect to an ethereum node. The resulting contract addresses are stored in output/contracts or ARTIFACT_OUTPUT_ROOT if defined.

## Tests

TODO

## Source code organization

Augur's smart contracts are organized into four folders:

-   `source/contracts/factories`: Constructors for universes, markets etc.
-   `source/contracts/libraries`: Data structures used elsewhere in the source code.
-   `source/contracts/reporting`: Creation and manipulation of universes, and markets.
-   `source/contracts/trading`: Functions to issue and close out complete sets of shares, and for traders to claim proceeds after markets are resolved.
