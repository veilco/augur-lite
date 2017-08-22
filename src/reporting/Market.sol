// Copyright (C) 2015 Forecast Foundation OU, full GPL notice in LICENSE

pragma solidity ^0.4.13;

import 'ROOT/legacy_reputation/Ownable.sol';
import 'ROOT/extensions/MarketExtensions.sol';
import 'ROOT/reporting/Branch.sol';
import 'ROOT/reporting/ReportingToken.sol';
import 'ROOT/reporting/ReputationToken.sol';
import 'ROOT/reporting/DisputeBondToken.sol';
import 'ROOT/reporting/Interfaces.sol';
import 'ROOT/trading/Cash.sol';
import 'ROOT/libraries/DelegationTarget.sol';
import 'ROOT/extensions/MarketFeeCalculator.sol';
import 'ROOT/factories/MapFactory.sol';
import 'ROOT/factories/ShareTokenFactory.sol';
import 'ROOT/factories/ReportingTokenFactory.sol';
import 'ROOT/factories/DisputeBondTokenFactory.sol';
import 'ROOT/libraries/Typed.sol';
import 'ROOT/libraries/Initializable.sol';
import 'ROOT/libraries/token/ERC20Basic.sol';
import 'ROOT/libraries/math/SafeMathUint256.sol';
import 'ROOT/libraries/math/SafeMathInt256.sol';


contract Market is DelegationTarget, Typed, Initializable, Ownable {
    using SafeMathUint256 for uint256;
    using SafeMathInt256 for int256;

    enum ReportingState {
        PRE_REPORTING,
        AUTOMATED_REPORTING,
        AUTOMATED_DISPUTE,
        LIMITED_REPORTING,
        LIMITED_DISPUTE,
        ALL_REPORTING,
        ALL_DISPUTE,
        FORK,
        FINALIZED
    }

    // CONSIDER: change the payoutNumerator/payoutDenominator to use fixed point numbers instead of integers; PRO: some people find fixed point decimal values easier to grok; CON: rounding errors can occur and it is easier to screw up the math if you don't handle fixed point values correctly
    uint256 private payoutDenominator;
    uint256 private feePerEthInAttoeth;

    // CONSIDER: we really don't need these
    int256 private maxDisplayPrice;
    int256 private minDisplayPrice;

    // CONSIDER: figure out approprate values for these
    uint256 private constant AUTOMATED_REPORTER_DISPUTE_BOND_AMOUNT = 11 * 10**20;
    uint256 private constant LIMITED_REPORTERS_DISPUTE_BOND_AMOUNT = 11 * 10**21;
    uint256 private constant ALL_REPORTERS_DISPUTE_BOND_AMOUNT = 11 * 10**22;

    uint256 private constant MAX_FEE_PER_ETH_IN_ATTOETH = 5 * 10 ** 17;
    uint256 private constant APPROVAL_AMOUNT = 2 ** 254;
    uint256 private constant AUTOMATED_REPORTING_DURATION_SECONDS = 3 days;
    uint256 private constant AUTOMATED_REPORTING_DISPUTE_DURATION_SECONDS = 3 days;
    address private constant NULL_ADDRESS = address(0);

    ReportingWindow private reportingWindow;
    uint256 private endTime;
    uint8 private numOutcomes;
    uint256 private marketCreationBlock;
    bytes32 private topic;
    address private automatedReporterAddress;
    mapping(bytes32 => ReportingToken) private reportingTokens;
    Cash private cash;
    IShareToken[] private shareTokens;
    uint256 private finalizationTime;
    bool private automatedReportReceived;
    bytes32 private tentativeWinningPayoutDistributionHash;
    bytes32 private finalPayoutDistributionHash;
    DisputeBondToken private automatedReporterDisputeBondToken;
    DisputeBondToken private limitedReportersDisputeBondToken;
    DisputeBondToken private allReportersDisputeBondToken;
    uint256 private validityBondAttoeth;
    uint256 private automatedReporterBondAttoeth;

    /**
     * @dev Makes the function trigger a migration before execution
     */
    modifier triggersMigration() {
        migrateThroughAllForks();
        _;
    }

    function initialize(ReportingWindow _reportingWindow, uint256 _endTime, uint8 _numOutcomes, uint256 _payoutDenominator, uint256 _feePerEthInAttoeth, Cash _cash, address _creator, int256 _minDisplayPrice, int256 _maxDisplayPrice, address _automatedReporterAddress, bytes32 _topic) public payable beforeInitialized returns (bool _success) {
        endInitialization();
        require(address(_reportingWindow) != NULL_ADDRESS);
        require(_numOutcomes >= 2);
        require(_numOutcomes <= 8);
        // payoutDenominator must be a multiple of numOutcomes so we can evenly split complete set share payout on indeterminate
        require((_payoutDenominator % _numOutcomes) == 0);
        require(feePerEthInAttoeth <= MAX_FEE_PER_ETH_IN_ATTOETH);
        require(_minDisplayPrice < _maxDisplayPrice);
        require(_creator != NULL_ADDRESS);
        require(_cash.getTypeName() == "Cash");
        // FIXME: require market to be on a non-forking branch; repeat this check up the stack as well if necessary (e.g., in reporting window)
        // CONSIDER: should we allow creator to send extra ETH, is there risk of variability in bond requirements?
        require(msg.value == MarketFeeCalculator(controller.lookup("MarketFeeCalculator")).getMarketCreationCost(_reportingWindow));
        reportingWindow = _reportingWindow;
        endTime = _endTime;
        numOutcomes = _numOutcomes;
        payoutDenominator = _payoutDenominator;
        feePerEthInAttoeth = _feePerEthInAttoeth;
        maxDisplayPrice = _maxDisplayPrice;
        minDisplayPrice = _minDisplayPrice;
        marketCreationBlock = block.number;
        topic = _topic;
        automatedReporterAddress = _automatedReporterAddress;
        cash = _cash;
        owner = _creator;
        for (uint8 _outcome = 0; _outcome < numOutcomes; _outcome++) {
            shareTokens.push(createShareToken(_outcome));
        }
        approveSpenders();
        _success = true;
        return _success;

        // TODO: we need to update this signature (and all of the places that call it) to allow the creator (UI) to pass in a number of other things which will all be logged here
        // TODO: log short description
        // TODO: log long description
        // TODO: log min display price
        // TODO: log max display price
        // TODO: log tags (0-2)
        // TODO: log outcome labels (same number as numOutcomes)
        // TODO: log type (scalar, binary, categorical)
        // TODO: log any immutable data associated with the market (e.g., endTime, numOutcomes, payoutDenominator, cash address, etc.)
    }

    function createShareToken(uint8 _outcome) private returns (IShareToken) {
        return ShareTokenFactory(controller.lookup("ShareTokenFactory")).createShareToken(controller, this, _outcome);
    }

    // this will need to be called manually for each open market if a spender contract is updated
    function approveSpenders() private returns (bool) {
        bytes32[5] memory _names = [bytes32("cancelOrder"), bytes32("completeSets"), bytes32("takeOrder"), bytes32("tradingEscapeHatch"), bytes32("claimProceeds")];
        for (uint8 i = 0; i < _names.length; i++) {
            cash.approve(controller.lookup(_names[i]), APPROVAL_AMOUNT);
        }
        for (uint8 j = 0; j < numOutcomes; j++) {
            shareTokens[j].approve(controller.lookup("takeOrder"), APPROVAL_AMOUNT);
        }
        return true;
    }

    function decreaseMarketCreatorSettlementFeeInAttoethPerEth(uint256 _newFeePerEthInWei) public onlyOwner returns (bool) {
        require(_newFeePerEthInWei < feePerEthInAttoeth);
        feePerEthInAttoeth = _newFeePerEthInWei;
        return true;
    }

    function automatedReport(uint256[] _payoutNumerators) public returns (bool) {
        // intentionally does not migrate the market as automated report markets won't actually migrate unless a dispute bond has been placed or the automated report doesn't occur
        require(msg.sender == automatedReporterAddress);
        require(isInAutomatedReportingPhase());
        // we have to create the reporting token so the rest of the system works (winning reporting token must exist)
        getReportingToken(_payoutNumerators);
        automatedReportReceived = true;
        tentativeWinningPayoutDistributionHash = derivePayoutDistributionHash(_payoutNumerators);
        reportingWindow.updateMarketPhase();
        return true;
    }

    function disputeAutomatedReport() public returns (bool) {
        // intentionally does not migrate the market as automated report markets won't actually migrate unless a dispute bond has been placed or the automated report doesn't occur
        require(isInAutomatedDisputePhase());
        automatedReporterDisputeBondToken = DisputeBondTokenFactory(controller.lookup("DisputeBondTokenFactory")).createDisputeBondToken(controller, this, msg.sender, AUTOMATED_REPORTER_DISPUTE_BOND_AMOUNT, tentativeWinningPayoutDistributionHash);
        fundDisputeBondWithReputation(msg.sender, automatedReporterDisputeBondToken, AUTOMATED_REPORTER_DISPUTE_BOND_AMOUNT);
        reportingWindow.updateMarketPhase();
        return true;
    }

    function disputeLimitedReporters() public triggersMigration returns (bool) {
        require(isInLimitedDisputePhase());
        limitedReportersDisputeBondToken = DisputeBondTokenFactory(controller.lookup("DisputeBondTokenFactory")).createDisputeBondToken(controller, this, msg.sender, LIMITED_REPORTERS_DISPUTE_BOND_AMOUNT, tentativeWinningPayoutDistributionHash);
        fundDisputeBondWithReputation(msg.sender, limitedReportersDisputeBondToken, LIMITED_REPORTERS_DISPUTE_BOND_AMOUNT);
        ReportingWindow _newReportingWindow = getBranch().getNextReportingWindow();
        return migrateReportingWindow(_newReportingWindow);
    }

    function disputeAllReporters() public triggersMigration returns (bool) {
        require(isInAllDisputePhase());
        allReportersDisputeBondToken = DisputeBondTokenFactory(controller.lookup("DisputeBondTokenFactory")).createDisputeBondToken(controller, this, msg.sender, ALL_REPORTERS_DISPUTE_BOND_AMOUNT, tentativeWinningPayoutDistributionHash);
        fundDisputeBondWithReputation(msg.sender, allReportersDisputeBondToken, ALL_REPORTERS_DISPUTE_BOND_AMOUNT);
        reportingWindow.getBranch().fork();
        ReportingWindow _newReportingWindow = getBranch().getReportingWindowForForkEndTime();
        return migrateReportingWindow(_newReportingWindow);
    }

    function migrateReportingWindow(ReportingWindow _newReportingWindow) private afterInitialized returns (bool) {
        _newReportingWindow.migrateMarketInFromSibling();
        reportingWindow.removeMarket();
        reportingWindow = _newReportingWindow;
        return true;
    }

    function updateTentativeWinningPayoutDistributionHash(bytes32 _payoutDistributionHash) public returns (bool) {
        ReportingToken _reportingToken = reportingTokens[_payoutDistributionHash];
        require(address(_reportingToken) != NULL_ADDRESS);

        ReportingToken _tentativeWinningReportingToken = reportingTokens[tentativeWinningPayoutDistributionHash];
        if (address(_tentativeWinningReportingToken) == NULL_ADDRESS) {
            tentativeWinningPayoutDistributionHash = _payoutDistributionHash;
            _tentativeWinningReportingToken = _reportingToken;
        }
        if (_reportingToken.totalSupply() > _tentativeWinningReportingToken.totalSupply()) {
            tentativeWinningPayoutDistributionHash = _payoutDistributionHash;
        }
        return true;
    }

    function tryFinalize() public returns (bool) {
        require(tentativeWinningPayoutDistributionHash != bytes32(0));

        if (isFinalized()) {
            return true;
        }

        if (getReportingState() == ReportingState.AUTOMATED_DISPUTE) {
            if (!canFinalizeAutomated()) {
                return false;
            }
        }
        if (getReportingState() == ReportingState.LIMITED_REPORTING || getReportingState() == ReportingState.ALL_REPORTING) {
            if (!canFinalizeReporting()) {
                return false;
            }
        }
        if (getReportingState() == ReportingState.FORK) {
            if (!canFinalizeFork()) {
                return false;
            }
        }

        finalPayoutDistributionHash = tentativeWinningPayoutDistributionHash;
        finalizationTime = block.timestamp;
        transferIncorrectDisputeBondsToWinningReportingToken();
        reportingWindow.updateMarketPhase();
        return true;
    }

        // FIXME: when the market is finalized, we need to add `reportingTokens[finalPayoutDistributionHash].totalSupply()` to the reporting window.  This is necessary for fee collection which is a cross-market operation.
        // TODO: figure out how to make it so fee distribution is delayed until all markets have been finalized; we can enforce it contract side and let the UI deal with the actual work
        // FIXME: if finalPayoutDistributionHash != getIdentityDistributionId(), pay back validity bond holder
        // FIXME: if finalPayoutDistributionHash == getIdentityDistributionId(), transfer validity bond to reportingWindow (reporter fee pot)
        // FIXME: if automated report is wrong, transfer automated report bond to reportingWindow
        // FIXME: if automated report is right, transfer automated report bond to market creator
        // FIXME: handle markets that get 0 reports during their scheduled reporting window

    function canFinalizeAutomated() private returns (bool) {
        if (!automatedReportReceived) {
            return false;
        }
        return true;
    }

    function canFinalizeReporting() private triggersMigration returns (bool) {
        if (block.timestamp <= reportingWindow.getEndTime()) {
            return false;
        }
        return true;
    }

    function canFinalizeFork() private returns (bool) {
        bytes32 _winningPayoutDistributionHash = MarketExtensions(controller.lookup("MarketExtensions")).getWinningPayoutDistributionHashFromFork(this);
        if (_winningPayoutDistributionHash == bytes32(0)) {
            return false;
        }
        tentativeWinningPayoutDistributionHash = _winningPayoutDistributionHash;
        return true;
    }

    function migrateThroughAllForks() public returns (bool) {
        // this will loop until we run out of gas, follow forks until there are no more, or have reached an active fork (which will throw)
        while (migrateThroughOneFork()) {
            continue;
        }
        return true;
    }

    // returns 0 if no move occurs, 1 if move occurred, throws if a fork not yet resolved
    function migrateThroughOneFork() public returns (bool) {
        if (isFinalized()) {
            return true;
        }
        if (!needsMigration()) {
            return false;
        }
        // only proceed if the forking market is finalized
        require(reportingWindow.isForkingMarketFinalized());
        Branch _currentBranch = getBranch();
        // follow the forking market to its branch and then attach to the next reporting window on that branch
        bytes32 _winningForkPayoutDistributionHash = _currentBranch.getForkingMarket().getFinalPayoutDistributionHash();
        Branch _destinationBranch = _currentBranch.getChildBranch(_winningForkPayoutDistributionHash);
        ReportingWindow _newReportingWindow = _destinationBranch.getNextReportingWindow();
        _newReportingWindow.migrateMarketInFromNibling();
        reportingWindow.removeMarket();
        reportingWindow = _newReportingWindow;
        // reset to unreported state
        limitedReportersDisputeBondToken = DisputeBondToken(0);
        allReportersDisputeBondToken = DisputeBondToken(0);
        tentativeWinningPayoutDistributionHash = 0;
        return true;
    }

    ////////
    //////// Helpers
    ////////

    function getReportingToken(uint256[] _payoutNumerators) public returns (ReportingToken) {
        bytes32 _payoutDistributionHash = derivePayoutDistributionHash(_payoutNumerators);
        ReportingToken _reportingToken = reportingTokens[_payoutDistributionHash];
        if (address(_reportingToken) == NULL_ADDRESS) {
            _reportingToken = ReportingTokenFactory(controller.lookup("ReportingTokenFactory")).createReportingToken(controller, this, _payoutNumerators);
            reportingTokens[_payoutDistributionHash] = _reportingToken;
        }
        return _reportingToken;
    }

    function fundDisputeBondWithReputation(address _bondHolder, DisputeBondToken _disputeBondToken, uint256 _bondAmount) private returns (bool) {
        require(_bondHolder == _disputeBondToken.getBondHolder());
        reportingWindow.getReputationToken().trustedTransfer(_bondHolder, _disputeBondToken, _bondAmount);
        return true;
    }

    function transferIncorrectDisputeBondsToWinningReportingToken() private returns (bool) {
        require(isFinalized());
        ReputationToken _reputationToken = reportingWindow.getReputationToken();
        if (getBranch().getForkingMarket() == this) {
            return true;
        }
        if (address(automatedReporterDisputeBondToken) != NULL_ADDRESS && automatedReporterDisputeBondToken.getDisputedPayoutDistributionHash() == finalPayoutDistributionHash) {
            _reputationToken.trustedTransfer(automatedReporterDisputeBondToken, getFinalWinningReportingToken(), _reputationToken.balanceOf(automatedReporterDisputeBondToken));
        }
        if (address(limitedReportersDisputeBondToken) != NULL_ADDRESS && limitedReportersDisputeBondToken.getDisputedPayoutDistributionHash() == finalPayoutDistributionHash) {
            _reputationToken.trustedTransfer(limitedReportersDisputeBondToken, getFinalWinningReportingToken(), _reputationToken.balanceOf(limitedReportersDisputeBondToken));
        }
        return true;
    }

    function derivePayoutDistributionHash(uint256[] _payoutNumerators) public constant returns (bytes32) {
        uint256 _sum = 0;
        require(_payoutNumerators.length == numOutcomes);
        for (uint8 i = 0; i < numOutcomes; i++) {
            require(_payoutNumerators[i] <= payoutDenominator);
            _sum += _payoutNumerators[i];
        }
        require(_sum == payoutDenominator);
        return sha3(_payoutNumerators);
    }

    function getReportingTokenOrZeroByPayoutDistributionHash(bytes32 _payoutDistributionHash) public constant returns (ReportingToken) {
        return reportingTokens[_payoutDistributionHash];
    }

    ////////
    //////// Getters
    ////////
    function getTypeName() public constant returns (bytes32) {
        return "Market";
    }

    function getReportingWindow() public constant returns (ReportingWindow) {
        return reportingWindow;
    }

    function getBranch() public constant returns (Branch) {
        return reportingWindow.getBranch();
    }

    function getAutomatedReporterDisputeBondToken() public constant returns (DisputeBondToken) {
        return automatedReporterDisputeBondToken;
    }

    function getLimitedReportersDisputeBondToken() public constant returns (DisputeBondToken) {
        return limitedReportersDisputeBondToken;
    }

    function getAllReportersDisputeBondToken() public constant returns (DisputeBondToken) {
        return allReportersDisputeBondToken;
    }

    function getNumberOfOutcomes() public constant returns (uint8) {
        return numOutcomes;
    }

    function getEndTime() public constant returns (uint256) {
        return endTime;
    }

    function getTentativeWinningPayoutDistributionHash() public constant returns (bytes32) {
        return tentativeWinningPayoutDistributionHash;
    }

    function getFinalWinningReportingToken() public constant returns (ReportingToken) {
        return reportingTokens[finalPayoutDistributionHash];
    }

    function getShareToken(uint8 outcome)  public constant returns (IShareToken) {
        require(outcome < numOutcomes);
        return shareTokens[outcome];
    }

    function getFinalPayoutDistributionHash() public constant returns (bytes32) {
        return finalPayoutDistributionHash;
    }

    function getPayoutDenominator() public constant returns (uint256) {
        return payoutDenominator;
    }

    function getDenominationToken() public constant returns (Cash) {
        return cash;
    }

    function getMarketCreatorSettlementFeeInAttoethPerEth() public constant returns (uint256) {
        return feePerEthInAttoeth;
    }

    function getMaxDisplayPrice() public constant returns (int256) {
        return maxDisplayPrice;
    }

    function getMinDisplayPrice() public constant returns (int256) {
        return minDisplayPrice;
    }

    function getCompleteSetCostInAttotokens() public constant returns (uint256) {
        return uint256(maxDisplayPrice.sub(minDisplayPrice));
    }

    function getTopic() public constant returns (bytes32) {
        return topic;
    }

    function shouldCollectReportingFees() public constant returns (bool) {
        return !getBranch().isContainerForShareToken(cash);
    }

    function isDoneWithAutomatedReporters() public constant returns (bool) {
        return automatedReportReceived || block.timestamp > getAutomatedReportDueTimestamp();
    }

    function isDoneWithLimitedReporters() public constant returns (bool) {
        return getReportingState() > ReportingState.LIMITED_REPORTING;
    }

    function isDoneWithAllReporters() public constant returns (bool) {
        return getReportingState() > ReportingState.ALL_REPORTING;
    }

    function isFinalized() public constant returns (bool) {
        return finalPayoutDistributionHash != bytes32(0);
    }

    function getFinalizationTime() public constant returns (uint256) {
        return finalizationTime;
    }

    function isInAutomatedReportingPhase() public constant returns (bool) {
        return getReportingState() == ReportingState.AUTOMATED_REPORTING;
    }

    function isInAutomatedDisputePhase() public constant returns (bool) {
        return getReportingState() == ReportingState.AUTOMATED_DISPUTE;
    }

    function isInLimitedReportingPhase() public constant returns (bool) {
        return getReportingState() == ReportingState.LIMITED_REPORTING;
    }

    function isInLimitedDisputePhase() public constant returns (bool) {
        return getReportingState() == ReportingState.LIMITED_DISPUTE;
    }

    function isInAllReportingPhase() public constant returns (bool) {
        return getReportingState() == ReportingState.ALL_REPORTING;
    }

    function isInAllDisputePhase() public constant returns (bool) {
        return getReportingState() == ReportingState.ALL_DISPUTE;
    }

    function isContainerForReportingToken(ReportingToken _shadyToken) public constant returns (bool) {
        if (address(_shadyToken) == NULL_ADDRESS) {
            return false;
        }
        if (_shadyToken.getTypeName() != "ReportingToken") {
            return false;
        }
        bytes32 _shadyId = _shadyToken.getPayoutDistributionHash();
        ReportingToken _reportingToken = reportingTokens[_shadyId];
        if (address(_reportingToken) == NULL_ADDRESS) {
            return false;
        }
        if (_reportingToken != _shadyToken) {
            return false;
        }
        return true;
    }

    function isContainerForShareToken(IShareToken _shadyShareToken) public constant returns (bool) {
        if (_shadyShareToken.getTypeName() != "ShareToken") {
            return false;
        }
        return(getShareToken(_shadyShareToken.getOutcome()) == _shadyShareToken);
    }

    function isContainerForDisputeBondToken(DisputeBondToken _shadyBondToken) public constant returns (bool) {
        if (_shadyBondToken.getTypeName() != "DisputeBondToken") {
            return false;
        }
        if (automatedReporterDisputeBondToken == _shadyBondToken) {
            return true;
        } else if (limitedReportersDisputeBondToken == _shadyBondToken) {
            return true;
        } else if (allReportersDisputeBondToken == _shadyBondToken) {
            return true;
        }
        return false;
    }

    function canBeReportedOn() public constant returns (bool) {
        // CONSIDER: should we check if migration is necessary here?
        if (isFinalized()) {
            return false;
        }
        if (!reportingWindow.isReportingActive()) {
            return false;
        }
        return true;
    }

    function needsMigration() public constant returns (bool) {
        if (isFinalized()) {
            return false;
        }
        Market _forkingMarket = getBranch().getForkingMarket();
        if (address(_forkingMarket) == NULL_ADDRESS) {
            return false;
        }
        if (_forkingMarket == this) {
            return false;
        }
        if (block.timestamp < endTime) {
            return false;
        }
        if (automatedReporterAddress != NULL_ADDRESS && block.timestamp < getAutomatedReportDueTimestamp()) {
            return false;
        }
        if (automatedReportReceived && block.timestamp < getAutomatedReportDisputeDueTimestamp()) {
            return false;
        }
        if (automatedReportReceived && address(automatedReporterDisputeBondToken) == NULL_ADDRESS) {
            return false;
        }
        return true;
    }

    function getAutomatedReportDueTimestamp() public constant returns (uint256) {
        return endTime + AUTOMATED_REPORTING_DURATION_SECONDS;
    }

    function getAutomatedReportDisputeDueTimestamp() public constant returns (uint256) {
        return getAutomatedReportDueTimestamp() + AUTOMATED_REPORTING_DISPUTE_DURATION_SECONDS;
    }

    function getReportingState() public constant returns (ReportingState) {
        if (isFinalized()) {
            return ReportingState.FINALIZED;
        }

        if (address(allReportersDisputeBondToken) != NULL_ADDRESS) {
            return ReportingState.FORK;
        }

        if (address(limitedReportersDisputeBondToken) != NULL_ADDRESS) {
            if (reportingWindow.isDisputeActive()) {
                return ReportingState.ALL_DISPUTE;
            }
            return ReportingState.ALL_REPORTING;
        }

        if (reportingWindow.isDisputeActive()) {
            return ReportingState.LIMITED_DISPUTE;
        }

        if (canBeReportedOn()) {
            return ReportingState.LIMITED_REPORTING;
        }

        if (block.timestamp > getAutomatedReportDueTimestamp() && block.timestamp < getAutomatedReportDisputeDueTimestamp()) {
            return ReportingState.AUTOMATED_DISPUTE;
        }

        if (block.timestamp > endTime && block.timestamp < getAutomatedReportDueTimestamp()) {
            return ReportingState.AUTOMATED_REPORTING;
        }

        return ReportingState.PRE_REPORTING;
    }
}