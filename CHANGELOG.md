# augur-lite CHANGELOG

As this repo is a fork of the Augur V1 contract code, available [here](https://github.com/AugurProject/augur-core), we'd like to enumarate high-level changes made to the codebase. We'll also list file-by-file changes made to the smart contracts.

## High-level technical changes

-   Smart contracts are updated to use pragma version 0.4.26.
-   Indentation for Typescript and Solidity files are updated to 2 spaces.
-   Deployment scripts are simplified with the removal of trading and reporting contracts.
-   Network configuration are updated to accept a denomination token to be used in the creation of the genesis universe.
-   Python tests are updated to account for removed functionality. When needed, market and universe tests were updated to use modified functionality (ie `doInitialReport` + `finalize` vs. `resolve`).
-   The Docker integration are removed to simplify the surface area of changes/testing.
-   The repo will be published on NPM as `augur-lite` for easily importing ABIs and contract addresses.

## File-by-file smart contract changes

Solidity smart contracts reside in `source/contracts`. Specifically:

-   `source/contracts/factories`: Constructors for universes, markets, share tokens etc.
-   `source/contracts/libraries`: Libraries (ie SafeMath) or utility contracts (ie MarketValidator) used elsewhere in the source code.
-   `source/contracts/reporting`: Contracts for managing universes and creating/managing markets.
-   `source/contracts/trading`: Contracts to issue and close out complete sets of shares, and for traders to claim proceeds after markets are resolved.

### Contract removals

This is the list of contracts that have been removed. Majority of the deletions are due to removal of functionality, as AugurLite doesn’t have on-chain trading, a reporting/dispute process, validity/no-show bonds, or a native token (ie REP in Augur).

-   Reporting contracts
    -   factories/
        -   DisputeCrowdSourcerFactory
        -   FeeTokenFactory
        -   FeeWindowFactory
        -   InitialReporterFactory
        -   ReputationTokenFactory
    -   legacy_reputation/
        -   BasicToken
        -   ERC20
        -   ERC20Basic
        -   Initializable
        -   LegacyRepToken
        -   OwnablePausable
        -   PausableToken
        -   SafeMath
        -   StandardToken
    -   reporting/
        -   BaseReportingParticipant
        -   DisputeCrowdsourcer
        -   FeeToken
        -   FeeWindow
        -   IDisputeCrowdsourcer
        -   IFeeToken
        -   IFeeWindow
        -   IInitialReporter
        -   InitialReporter
        -   IReportingParticipant
        -   IRepPriceOracle
        -   IReputationToken
        -   Reporting
        -   RepPriceOracle
        -   ReputationToken
    -   /
        -   LegacyReputationToken
        -   TestNetReputationToken
-   Trading contracts
    -   external/
        -   EscapeHatchController
        -   OrdersFinder
    -   trading/
        -   CancelOrder
        -   Cash
        -   CreateOrder
        -   FillOrder
        -   ICancelOrder
        -   ICash
        -   ICreateOrder
        -   IFillOrder
        -   IOrders
        -   IOrdersFetcher
        -   ITrade
        -   ITradingEscapeHatch
        -   Order
        -   Orders
        -   OrdersFetcher
        -   Trade
        -   TradingEscapeHatch
    -   libraries/
        -   CashAutoConverter
-   Utility/library contracts
    -   libraries/
        -   collections/Map
        -   ContractExists
    -   factories/
        -   MapFactory

### Contract modifications

This is a list of contract modifications. If a contract name is not listed, it means there hasn't been any changes (except indentation and compiler update).

-   /
    -   `AugurLite.sol`
        -   This was originally the `Augur.sol` file.
        -   `TokenType` enum was pruned to only include `ShareToken`, as the rest of the tokens are removed.
        -   The following events were removed, as well as the methods that triggered them (ie `InitialReportSubmitted` event was emitted by `logInitialReportSubmitted`, this method was also removed) `InitialReportSubmitted`, `DisputeCrowdsourcerCreated`, `DisputeCrowdsourcerContribution`, `DisputeCrowdsourcerCompleted`, `InitialReporterRedeemed`, `DisputeCrowdsourcerRedeemed`, `ReportingParticipantDisavowed`, `MarketParticipantsDisavowed`, `FeeWindowRedeemed`, `MarketMigrated`, `UniverseForked`, `OrderCanceled`, `OrderCreated`, `OrderFilled`, `FeeWindowCreated`, `InitialReporterTransferred`, `EscapeHatchChanged`
        -   The following events were added/modified: `UniverseCreated` was modified to also emit the denomination token of the universe. `MarketFinalized` was renamed to `MarketResolved`, and `logMarketFinalized` method was renamed to `logMarketResolved`.
        -   Per the compiler update, the events are now triggered with the `emit` keyword.
        -   With the removal of disputes from the base protocol, the code related to `DisputeCrowdsourcers` was removed.
        -   With the removal of forking from the base protocol:
            -   `createGenesisUniverse` was merged with the `createUniverse` method. The method now accepts the `denominationToken` that the created universe will support as an argument.
            -   `createChildUniverse` was removed.
    -   `Controlled.sol`
        -   Per the compiler update, the contract was updated to use `constructor`.
    -   `Controller.sol`
        -   It was updated to use the new `IAugurLite` interface.
        -   `getAugur` method was renamed to `getAugurLite`.
    -   `IAugurLite.sol`
        -   This was originally named `IAugur.sol`.
        -   `logMarketFinalized` method was renamed to `logMarketResolved`.
        -   Methods that were deleted from `AugurLite.sol` were removed.
    -   `IController.sol`
        -   It was updated to use the new `IAugurLite` interface.
        -   `getAugur` method was renamed to `getAugurLite`.
    -   `TimeControlled.sol`
        -   Per the compiler update, the contract was updated to use `constructor`.
        -   Removed the concept of the foundation network. This led to the removal of the `ContractExists` library.
        -   `getAugur` method call was renamed to `getAugurLite`.
-   factories/
    -   `MarketFactory.sol`
        -   Changed `ICash` to generic `ERC20` library.
        -   Removed the requirement for the reputation token transfer as it isn't used.
        -   `designatedReporterAddress` is renamed to `oracle`.
    -   `UniverseFactory.sol`
        -   `createUniverse` method now only accepts `denominationToken` as an argument. The concepts of `parentUniverse` and `parentPayoutDistributionHash` are removed, as there's no concept of forking or children-parent universes.
-   libraries/
    -   `Delegator.sol`
        -   Per the compiler update, the contract was updated to use `constructor`.
    -   `MarketValidator.sol`
        -   `getAugur` method call was renamed to `getAugurLite`.
    -   `Ownable.sol`
        -   Per the compiler update, the contract was updated to use `constructor`.
    -   `token/BasicToken.sol`
        -   Per the compiler update, the events are now triggered with the `emit` keyword.
    -   `token/StandardToken.sol`
        -   Per the compiler update, the events are now triggered with the `emit` keyword.
    -   `token/VariableSupplyToken.sol`
        -   Per the compiler update, the events are now triggered with the `emit` keyword.
-   reporting/
    -   `IMailbox.sol`
        -   `depositEther` method was removed.
    -   `IMarket.sol`
        -   Because there is no concept of forks, fee windows/tokens or REP, the following methods were removed: `getFeeWindow`, `getForkingMarket`, `getReputationToken`, `isContainerForReportingParticipant`, `designatedReporterWasCorrect`, `designatedReporterShowed`, `finalizeFork`.
        -   Because the reporting/dispute process is replaced by a single oracle, there is a single `resolve` method. `doInitialReport` and `finalize` methods are removed. Following this, these methods were removed: `derivePayoutDistributionHash`, `getWinningPayoutDistributionHash`, `getWinningPayoutNumerator`, `getFinalizationTime`, `isFinalized`.
        -   Some of the above methods were replaced with: `getPayoutNumerator`, `getResolutionTime`, `getOracle`, `isResolved`
    -   `IUniverse.sol`
        -   Because there is no concept of disputes, forks, fee windows/tokens or REP, the following methods were removed: `fork`, `getParentUniverse`, `createChildUniverse`, `getChildUniverse`, `getReputationToken`, `getForkingMarket`, `getForkEndTime`, `getForkReputationGoal`, `getParentPayoutDistributionHash`, `getDisputeRoundDurationInSeconds`, `getOrCreateFeeWindowByTimestamp`, `getOrCreateCurrentFeeWindow`, `getOrCreateNextFeeWindow`, `getRepMarketCapInAttoeth`, `getTargetRepMarketCapInAttoeth`, `getOrCacheValidityBond`, `getOrCacheDesignatedReportStake`, `getOrCacheDesignatedReportNoShowBond`, `getOrCacheReportingFeeDivisor`, `getDisputeThresholdForFork`, `getInitialReportMinValue`, `calculateFloatingValue`, `getOrCacheMarketCreationCost`, `getCurrentFeeWindow`, `getOrCreateFeeWindowBefore`, `isParentOf`, `updateTentativeWinningChildUniverse`, `isContainerForFeeWindow`, `isContainerForReportingParticipant`, `isContainerForFeeToken`, `addMarketTo`, `removeMarketFrom`, `getWinningChildUniverse`, `isForking`
        -   Because we don't track universe-wide open interest, the following methods were removed: `decrementOpenInterest`, `decrementOpenInterestFromMarket`, `incrementOpenInterest`, `incrementOpenInterestFromMarket`, `getOpenInterestInAttoEth`.
        -   `getDenominationToken` was added, as now the universe stores the denomination token.
        -   `initialize` method was modified to accept `denominationToken` as a param.
    -   `Mailbox.sol`
        -   `depositEther` and `withdrawEther` methods were removed.
        -   `CASH` usage is removed.
        -   `getAugur` method call was renamed to `getAugurLite`.
    -   `Market.sol`
        -   Because the reporting/dispute process is replaced by a single oracle, there is a single `resolve` method. `doInitialReport` and `finalize` methods are removed. Following this, the functionality of `derivePayoutDistributionHash` as a way to verify resolution information is kept, but the `payoutDistributionHash` is removed.
        -   TODO
    -   `Universe.sol`
        -   Besides the method deletions listed under `IUniverse.sol`, all the relevant contract state variables are removed. Remaining variables are `markets` and `denominationToken` (recent addition).
        -   `initialize` method was modified to accept `denominationToken` as a param.
        -   `getAugur` method call was renamed to `getAugurLite`.
        -   Market creation doesn't involve reputation token transfer, as there is no reputation token.
-   trading/
    -   `ClaimTradingProceeds.sol`
        -   `IClaimingTradingProceeds.sol` import was removed as it was empty.
        -   Changed `ICash` to generic `ERC20` library.
        -   Because there are no reporter fees, `calculateReporterFee` is removed, and `divideUpWinnings` only calls `calculateCreatorFee` for fees.
        -   `logTradingProceedsClaimed` uses the balance of the sender for the market denomination token, instead of their ETH balance.
    -   `CompleteSets.sol`
        -   `getAugur` method call was renamed to `getAugurLite`.
        -   `publicBuyCompleteSetsWithCash` and `publicSellCompleteSetsWithCash` were removed as there is no concept of `CASH`.
        -   `buyCompleteSets` was updated to not increment universe open interest, as that is not tracked any more.
        -   `sellCompleteSets` doesn't deal with `reporterFee`, and only takes `creatorFee` into account. It returns a success boolean, instead of `creatorFee` and `reporterFee`.
    -   `ICompleteSets.sol`
        -   `sellCompleteSets` returns a success boolean, instead of `creatorFee` and `reporterFee`.
    -   `IShareToken.sol`
        -   `trustedOrderTransfer`, `trustedFillOrderTransfer`, and `trustedCancelOrderTransfer` methods were removed.
    -   `ShareToken.sol`
        -   `trustedOrderTransfer`, `trustedFillOrderTransfer`, and `trustedCancelOrderTransfer` methods were removed.
        -   `getAugur` method call was renamed to `getAugurLite`.
