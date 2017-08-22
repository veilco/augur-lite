from datetime import timedelta
from ethereum.tools import tester
from ethereum.tools.tester import TransactionFailed
from pytest import raises
from utils import longToHexString, stringToBytes

tester.STARTGAS = long(6.7 * 10**6)

def test_market_creation(contractsFixture):
    branch = contractsFixture.branch
    cash = contractsFixture.cash
    market = contractsFixture.binaryMarket
    reportingWindow = contractsFixture.applySignature('ReportingWindow', market.getReportingWindow())
    shadyReportingToken = contractsFixture.upload('../src/reporting/ReportingToken.sol', 'shadyReportingToken')
    shadyReportingToken.initialize(market.address, [0,2])

    shareToken = contractsFixture.applySignature('shareToken', market.getShareToken(0))
    with raises(TransactionFailed, message="Markets can only use Cash as their denomination token"):
        contractsFixture.createReasonableBinaryMarket(branch, shareToken)

    assert market.getBranch() == branch.address
    assert market.getNumberOfOutcomes() == 2
    assert market.getPayoutDenominator() == 2
    assert reportingWindow.getReputationToken() == branch.getReputationToken()
    assert market.getFinalPayoutDistributionHash() == stringToBytes("")
    assert market.isDoneWithAutomatedReporters() == 0
    assert market.isDoneWithAllReporters() == 0
    assert market.isDoneWithLimitedReporters() == 0
    assert market.isFinalized() == 0
    assert market.isInAutomatedReportingPhase() == 0
    assert market.isInAutomatedDisputePhase() == 0
    assert market.isInLimitedReportingPhase() == 0
    assert market.isInLimitedDisputePhase() == 0
    assert market.isInAllReportingPhase() == 0
    assert market.isInAllDisputePhase() == 0
    assert market.isContainerForReportingToken(shadyReportingToken.address) == 0
    assert market.canBeReportedOn() == 0
    assert market.needsMigration() == 0
    assert market.getAutomatedReportDueTimestamp() == market.getEndTime() + timedelta(days=3).total_seconds()
