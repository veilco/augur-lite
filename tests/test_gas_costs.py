from ethereum.tools import tester
from ethereum.tools.tester import ABIContract, TransactionFailed
from pytest import fixture, mark, raises
from utils import longTo32Bytes, PrintGasUsed, fix
from datetime import timedelta
from trading.test_claimTradingProceeds import acquireLongShares, finalizeMarket
from reporting_utils import proceedToResolution

# Market Methods
MARKET_CREATION =               1758793
RESOLVE =                       1061824

pytestmark = mark.skip(reason="Just for testing gas cost")

tester.STARTGAS = long(6.7 * 10**6)

def test_marketCreation(localFixture, universe, testNetDenominationToken):
    marketCreationFee = universe.getOrCacheMarketCreationCost()

    endTime = long(localFixture.chain.head_state.timestamp + timedelta(days=1).total_seconds())
    feePerEthInWei = 10**16
    denominationToken = testNetDenominationToken
    designatedReporterAddress = tester.a0
    numTicks = 10 ** 18
    numOutcomes = 2

    with PrintGasUsed(localFixture, "FeeWindow:createMarket", MARKET_CREATION):
        marketAddress = universe.createYesNoMarket(endTime, feePerEthInWei, denominationToken.address, designatedReporterAddress, "", "description", "", value = marketCreationFee)

def test_resolve(localFixture, market):
    proceedToDesignatedReporting(localFixture, market)

    with PrintGasUsed(localFixture, "Market:resolve", RESOLVE):
        market.resolve([0, market.getNumTicks()], False)


@fixture(scope="session")
def localSnapshot(fixture, kitchenSinkSnapshot):
    fixture.resetToSnapshot(kitchenSinkSnapshot)
    universe = ABIContract(fixture.chain, kitchenSinkSnapshot['universe'].translator, kitchenSinkSnapshot['universe'].address)
    market = ABIContract(fixture.chain, kitchenSinkSnapshot['yesNoMarket'].translator, kitchenSinkSnapshot['yesNoMarket'].address)
    # Give some REP to testers to make things interesting
    reputationToken = fixture.applySignature('ReputationToken', universe.getReputationToken())
    for testAccount in [tester.a1, tester.a2, tester.a3]:
        reputationToken.transfer(testAccount, 1 * 10**6 * 10**18)

    return fixture.createSnapshot()

@fixture
def localFixture(fixture, localSnapshot):
    fixture.resetToSnapshot(localSnapshot)
    return fixture

@fixture
def universe(localFixture, kitchenSinkSnapshot):
    return ABIContract(localFixture.chain, kitchenSinkSnapshot['universe'].translator, kitchenSinkSnapshot['universe'].address)

@fixture
def market(localFixture, kitchenSinkSnapshot):
    return ABIContract(localFixture.chain, kitchenSinkSnapshot['yesNoMarket'].translator, kitchenSinkSnapshot['yesNoMarket'].address)

@fixture
def categoricalMarket(localFixture, kitchenSinkSnapshot):
    return ABIContract(localFixture.chain, kitchenSinkSnapshot['categoricalMarket'].translator, kitchenSinkSnapshot['categoricalMarket'].address)

@fixture
def scalarMarket(localFixture, kitchenSinkSnapshot):
    return ABIContract(localFixture.chain, kitchenSinkSnapshot['scalarMarket'].translator, kitchenSinkSnapshot['scalarMarket'].address)

@fixture
def testNetDenominationToken(localFixture, kitchenSinkSnapshot):
    return ABIContract(localFixture.chain, kitchenSinkSnapshot['testNetDenominationToken'].translator, kitchenSinkSnapshot['testNetDenominationToken'].address)
