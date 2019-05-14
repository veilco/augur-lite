from datetime import timedelta
from ethereum.tools import tester
from ethereum.tools.tester import TransactionFailed
from pytest import raises
from utils import stringToBytes, AssertLog, bytesToHexString

tester.STARTGAS = long(6.7 * 10**6)

def test_market_creation(contractsFixture, universe, testNetDenominationToken, market):
    numTicks = market.getNumTicks()

    market = None

    marketCreatedLog = {
        "extraInfo": 'so extra',
        "marketCreator": bytesToHexString(tester.a0),
    }
    with AssertLog(contractsFixture, "MarketCreated", marketCreatedLog):
        market = contractsFixture.createReasonableYesNoMarket(universe, testNetDenominationToken, extraInfo="so extra")

    assert market.getUniverse() == universe.address
    assert market.getNumberOfOutcomes() == 2
    assert numTicks == 10000
    assert market.isResolved() == False
    assert market.getInitialized()
    feeDivisor = 100

    with raises(TransactionFailed, message="Cannot create a market with an end date in the past"):
        contractsFixture.createYesNoMarket(universe, 0, feeDivisor, testNetDenominationToken, tester.a0)

def test_description_requirement(contractsFixture, universe, testNetDenominationToken):
    endTime = contractsFixture.contracts["Time"].getTimestamp() + 1
    feeDivisor = 100

    with raises(TransactionFailed):
        contractsFixture.createYesNoMarket(universe, endTime, feeDivisor, testNetDenominationToken, tester.a0, description="")

    with raises(TransactionFailed):
        contractsFixture.createCategoricalMarket(universe, 2, endTime, feeDivisor, testNetDenominationToken, tester.a0, description="")

    with raises(TransactionFailed):
        contractsFixture.createScalarMarket(universe, endTime, feeDivisor, testNetDenominationToken, 0, 1, 10000, tester.a0, description="")

def test_categorical_market_creation(contractsFixture, universe, testNetDenominationToken):
    endTime = contractsFixture.contracts["Time"].getTimestamp() + 1
    feeDivisor = 100

    with raises(TransactionFailed):
        contractsFixture.createCategoricalMarket(universe, 1, endTime, feeDivisor, testNetDenominationToken, tester.a0)

    assert contractsFixture.createCategoricalMarket(universe, 3, endTime, feeDivisor, testNetDenominationToken, tester.a0)
    assert contractsFixture.createCategoricalMarket(universe, 4, endTime, feeDivisor, testNetDenominationToken, tester.a0)
    assert contractsFixture.createCategoricalMarket(universe, 5, endTime, feeDivisor, testNetDenominationToken, tester.a0)
    assert contractsFixture.createCategoricalMarket(universe, 6, endTime, feeDivisor, testNetDenominationToken, tester.a0)
    assert contractsFixture.createCategoricalMarket(universe, 7, endTime, feeDivisor, testNetDenominationToken, tester.a0)
    assert contractsFixture.createCategoricalMarket(universe, 8, endTime, feeDivisor, testNetDenominationToken, tester.a0)

def test_num_ticks_validation(contractsFixture, universe, testNetDenominationToken):
    # Require numTicks != 0
    with raises(TransactionFailed):
       market = contractsFixture.createReasonableScalarMarket(universe, 30, -10, 0, testNetDenominationToken)

def test_transfering_ownership(contractsFixture, universe, market):

    transferLog = {
        "universe": universe.address,
        "market": market.address,
        "from": bytesToHexString(tester.a0),
        "to": bytesToHexString(tester.a1),
    }
    with AssertLog(contractsFixture, "MarketTransferred", transferLog):
        assert market.transferOwnership(tester.a1)

    mailbox = contractsFixture.applySignature('Mailbox', market.getMarketCreatorMailbox())

    transferLog = {
        "universe": universe.address,
        "market": market.address,
        "from": bytesToHexString(tester.a0),
        "to": bytesToHexString(tester.a1),
    }
    with AssertLog(contractsFixture, "MarketMailboxTransferred", transferLog):
        assert mailbox.transferOwnership(tester.a1)
