from ethereum.tools import tester
from utils import longToHexString, stringToBytes, bytesToHexString, twentyZeros, thirtyTwoZeros, longTo32Bytes
from pytest import fixture, raises
from ethereum.tools.tester import TransactionFailed

numTicks = 10 ** 10
def test_market_creation(localFixture, mockUniverse, mockTestNetDenominationToken, chain, mockMarket, mockShareToken, mockShareTokenFactory):
    feeDivisor = 100
    minFeeDivisor = 2
    endTime = localFixture.contracts["Time"].getTimestamp() + 259200
    market = localFixture.upload('../source/contracts/Market.sol', 'newMarket')
    market.setController(localFixture.contracts["Controller"].address)

    with raises(TransactionFailed, message="outcomes has to be greater than 1"):
        market.initialize(mockUniverse.address, endTime, feeDivisor, mockTestNetDenominationToken.address, tester.a1, tester.a1, 1, numTicks)

    with raises(TransactionFailed, message="outcomes has to be less than 9"):
        market.initialize(mockUniverse.address, endTime, feeDivisor, mockTestNetDenominationToken.address, tester.a1, tester.a1, 9, numTicks)

    with raises(TransactionFailed, message="feeDivisor cannot be between 0 and 2"):
        market.initialize(mockUniverse.address, endTime, minFeeDivisor - 1, mockTestNetDenominationToken.address, tester.a1, tester.a1, 5, numTicks)

    with raises(TransactionFailed, message="creator address can not be 0"):
        market.initialize(mockUniverse.address, endTime, feeDivisor, mockTestNetDenominationToken.address, longToHexString(0), tester.a1, 5, numTicks)

    with raises(TransactionFailed, message="oracle address can not be 0"):
        market.initialize(mockUniverse.address, endTime, feeDivisor, mockTestNetDenominationToken.address, tester.a1, longToHexString(0), 5, numTicks)

    with raises(TransactionFailed, message="denomination token cannot be different from universe denomination token"):
        market.initialize(mockUniverse.address, endTime, feeDivisor, "0x0000000000000000000000000000000000000000", tester.a1, longToHexString(0), 5, numTicks)

    mockShareTokenFactory.resetCreateShareToken()
    assert market.initialize(mockUniverse.address, endTime, feeDivisor, mockTestNetDenominationToken.address, tester.a1, tester.a1, 5, numTicks)
    assert mockShareTokenFactory.getCreateShareTokenMarketValue() == market.address
    assert mockShareTokenFactory.getCreateShareTokenOutcomeValue() == 5 - 1 # mock logs the last outcome
    assert market.getTypeName() == stringToBytes("Market")
    assert market.getUniverse() == mockUniverse.address
    assert market.getOracle() == bytesToHexString(tester.a1)
    assert market.getNumberOfOutcomes() == 5
    assert market.getEndTime() == endTime
    assert market.getNumTicks() == numTicks
    assert market.getDenominationToken() == mockTestNetDenominationToken.address
    assert market.getMarketCreatorSettlementFeeDivisor() == feeDivisor
    assert mockShareTokenFactory.getCreateShareTokenCounter() == 5
    assert mockShareTokenFactory.getCreateShareToken(0) == market.getShareToken(0)
    assert mockShareTokenFactory.getCreateShareToken(1) == market.getShareToken(1)
    assert mockShareTokenFactory.getCreateShareToken(2) == market.getShareToken(2)
    assert mockShareTokenFactory.getCreateShareToken(3) == market.getShareToken(3)
    assert mockShareTokenFactory.getCreateShareToken(4) == market.getShareToken(4)

def test_resolve(localFixture, initializedMarket, mockUniverse):
    # We can't resolve till the market has ended
    with raises(TransactionFailed, message="initial report allowed before market end time"):
        initializedMarket.resolve([initializedMarket.getNumTicks(), 0, 0, 0, 0], False, sender=tester.k1)

    localFixture.contracts["Time"].setTimestamp(initializedMarket.getEndTime() + 1)

    # Only the designated reporter can report at this time
    with raises(TransactionFailed, message="only the oracle can report at this time"):
        assert initializedMarket.resolve([initializedMarket.getNumTicks(), 0, 0, 0, 0], False)

    assert initializedMarket.resolve([initializedMarket.getNumTicks(), 0, 0, 0, 0], False, sender=tester.k1)
    assert initializedMarket.isResolved()

def test_approve_spenders(localFixture, initializedMarket, mockTestNetDenominationToken, mockShareTokenFactory):
    approvalAmount = 2**256-1
    # approveSpender was called as part of market initialization
    initializedMarket.approveSpenders()
    CompleteSets = localFixture.contracts['CompleteSets']
    assert mockTestNetDenominationToken.getApproveValueFor(CompleteSets.address) == approvalAmount
    ClaimTradingProceeds = localFixture.contracts['ClaimTradingProceeds']
    assert mockTestNetDenominationToken.getApproveValueFor(ClaimTradingProceeds.address) == approvalAmount

@fixture(scope="module")
def localSnapshot(fixture, augurInitializedWithMocksSnapshot):
    fixture.resetToSnapshot(augurInitializedWithMocksSnapshot)
    controller = fixture.contracts['Controller']
    mockTestNetDenominationToken = fixture.contracts['MockTestNetDenominationToken']
    mockAugurLite = fixture.contracts['MockAugurLite']
    mockShareTokenFactory = fixture.contracts['MockShareTokenFactory']
    mockShareToken = fixture.contracts['MockShareToken']

    # pre populate share tokens for max of 8 possible outcomes
    for index in range(8):
        item = fixture.uploadAndAddToController('solidity_test_helpers/MockShareToken.sol', 'newMockShareToken' + str(index));
        mockShareTokenFactory.pushCreateShareToken(item.address)

    controller.registerContract(stringToBytes('MockTestNetDenominationToken'), mockTestNetDenominationToken.address, twentyZeros, thirtyTwoZeros)
    controller.registerContract(stringToBytes('ShareTokenFactory'), mockShareTokenFactory.address, twentyZeros, thirtyTwoZeros)
    mockShareTokenFactory.resetCreateShareToken()

    mockUniverse = fixture.contracts['MockUniverse']
    mockUniverse.setDenominationToken(mockTestNetDenominationToken.address)

    market = fixture.upload('../source/contracts/Market.sol', 'market')
    fixture.contracts["initializedMarket"] = market
    endTime = fixture.contracts["Time"].getTimestamp() + 259200
    market.setController(fixture.contracts["Controller"].address)

    assert market.initialize(mockUniverse.address, endTime, 16, mockTestNetDenominationToken.address, tester.a1, tester.a2, 5, numTicks)

    return fixture.createSnapshot()

@fixture
def localFixture(fixture, localSnapshot):
    fixture.resetToSnapshot(localSnapshot)
    return fixture

@fixture
def mockUniverse(localFixture):
    return localFixture.contracts['MockUniverse']

@fixture
def mockTestNetDenominationToken(localFixture):
    return localFixture.contracts['MockTestNetDenominationToken']

@fixture
def chain(localFixture):
    return localFixture.chain

@fixture
def mockMarket(localFixture):
    return localFixture.contracts['MockMarket']

@fixture
def mockAugurLite(localFixture):
    return localFixture.contracts['MockAugurLite']

@fixture
def mockShareToken(localFixture):
    return localFixture.contracts['MockShareToken']

@fixture
def mockShareTokenFactory(localFixture):
    return localFixture.contracts['MockShareTokenFactory']

@fixture
def initializedMarket(localFixture):
    return localFixture.contracts["initializedMarket"]
