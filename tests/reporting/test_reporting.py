from ethereum.tools import tester
from ethereum.tools.tester import TransactionFailed
from pytest import fixture, raises
from utils import AssertLog
from reporting_utils import proceedToResolution

tester.STARTGAS = long(6.7 * 10**6)

def test_resolve(localFixture, universe, market):
    # proceed to the designated reporting period
    proceedToResolution(localFixture, market)

    # an address that is not the oracle cannot report
    with raises(TransactionFailed):
        market.resolve([0, market.getNumTicks()], False, sender=tester.k1)

    # Resolution with an invalid number of outcomes should fail
    with raises(TransactionFailed):
        market.resolve([0, 0, market.getNumTicks()], False)

    # Resolve as the oracle
    resolutionLog = {
        "universe": universe.address,
        "market": market.address,
    }
    with AssertLog(localFixture, "MarketResolved", resolutionLog):
        assert market.resolve([0, market.getNumTicks()], False)

    with raises(TransactionFailed, message="Cannot initial report twice"):
        assert market.resolve([0, market.getNumTicks()], False)

@fixture(scope="session")
def localSnapshot(fixture, kitchenSinkSnapshot):
    fixture.resetToSnapshot(kitchenSinkSnapshot)
    return fixture.createSnapshot()

@fixture
def localFixture(fixture, localSnapshot):
    fixture.resetToSnapshot(localSnapshot)
    return fixture

@fixture
def constants(localFixture, kitchenSinkSnapshot):
    return localFixture.contracts['Constants']
