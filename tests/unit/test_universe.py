from ethereum.tools import tester
from ethereum.tools.tester import TransactionFailed
from utils import longToHexString, stringToBytes, twentyZeros, thirtyTwoZeros, bytesToHexString
from pytest import fixture, raises

def test_universe_creation(localFixture):
    universe = localFixture.upload('../source/contracts/Universe.sol', 'newUniverse')
    universe.setController(localFixture.contracts['Controller'].address)
    assert universe.getTypeName() == stringToBytes('Universe')

def test_universe_contains(localFixture, populatedUniverse, mockMarket, chain, mockTestNetDenominationToken, mockMarketFactory, mockShareToken):
    assert populatedUniverse.isContainerForMarket(mockMarket.address) == False
    assert populatedUniverse.isContainerForShareToken(mockShareToken.address) == False

    timestamp = localFixture.contracts["Time"].getTimestamp()
    mockMarket.setIsContainerForShareToken(False)

    assert populatedUniverse.isContainerForMarket(mockMarket.address) == False
    assert populatedUniverse.isContainerForShareToken(mockShareToken.address) == False

    mockMarket.setIsContainerForShareToken(True)
    mockShareToken.setMarket(mockMarket.address)

    mockMarketFactory.setMarket(mockMarket.address)
    endTime = localFixture.contracts["Time"].getTimestamp() + 30 * 24 * 60 * 60 # 30 days

    assert populatedUniverse.createYesNoMarket(endTime, 1000, mockTestNetDenominationToken.address, tester.a0, "topic", "description", "info")
    assert mockMarketFactory.getCreateMarketUniverseValue() == populatedUniverse.address

    assert populatedUniverse.isContainerForMarket(mockMarket.address) == True
    assert populatedUniverse.isContainerForShareToken(mockShareToken.address) == True

def test_universe_create_market(localFixture, chain, populatedUniverse, mockMarket, mockMarketFactory, mockTestNetDenominationToken, mockAugurLite):
    timestamp = localFixture.contracts["Time"].getTimestamp()
    endTimeValue = timestamp + 10
    feePerEthInWeiValue = 10 ** 18
    oracle = tester.a2

    assert mockAugurLite.logMarketCreatedCalled() == False
    mockMarketFactory.setMarket(mockMarket.address)

    newMarket = populatedUniverse.createYesNoMarket(endTimeValue, feePerEthInWeiValue, mockTestNetDenominationToken.address, oracle, "topic", "description", "info")

    assert mockMarketFactory.getCreateMarketUniverseValue() == populatedUniverse.address
    assert populatedUniverse.isContainerForMarket(mockMarket.address)
    assert mockAugurLite.logMarketCreatedCalled() == True
    assert newMarket == mockMarket.address

@fixture(scope="module")
def localSnapshot(fixture, augurInitializedWithMocksSnapshot):
    fixture.resetToSnapshot(augurInitializedWithMocksSnapshot)
    controller = fixture.contracts['Controller']
    mockMarketFactory = fixture.contracts['MockMarketFactory']
    mockUniverseFactory = fixture.contracts['MockUniverseFactory']
    controller.registerContract(stringToBytes('MarketFactory'), mockMarketFactory.address, twentyZeros, thirtyTwoZeros)
    controller.registerContract(stringToBytes('UniverseFactory'), mockUniverseFactory.address, twentyZeros, thirtyTwoZeros)
    mockUniverse = fixture.contracts['MockUniverse']

    universe = fixture.upload('../source/contracts/Universe.sol', 'universe')
    fixture.contracts['populatedUniverse'] = universe
    universe.setController(fixture.contracts['Controller'].address)

    return fixture.createSnapshot()

@fixture
def localFixture(fixture, localSnapshot):
    fixture.resetToSnapshot(localSnapshot)
    return fixture

@fixture
def chain(localFixture):
    return localFixture.chain

@fixture
def mockUniverseFactory(localFixture):
    return localFixture.contracts['MockUniverseFactory']

@fixture
def mockMarketFactory(localFixture):
    return localFixture.contracts['MockMarketFactory']

@fixture
def mockUniverse(localFixture):
    return localFixture.contracts['MockUniverse']

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
def mockTestNetDenominationToken(localFixture):
    return localFixture.contracts['MockTestNetDenominationToken']

@fixture
def populatedUniverse(localFixture, mockUniverse):
    return localFixture.contracts['populatedUniverse']
