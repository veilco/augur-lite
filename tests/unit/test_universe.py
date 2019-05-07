from ethereum.tools import tester
from ethereum.tools.tester import TransactionFailed
from utils import longToHexString, stringToBytes, twentyZeros, thirtyTwoZeros, bytesToHexString
from pytest import fixture, raises

def test_universe_creation(localFixture, mockReputationToken, mockReputationTokenFactory, mockUniverse, mockUniverseFactory, mockAugur):
    universe = localFixture.upload('../source/contracts/reporting/Universe.sol', 'newUniverse')

    with raises(TransactionFailed, message="reputation token can not be address 0"):
        universe.initialize(mockUniverse.address, stringToBytes("5"))

    mockReputationTokenFactory.setCreateReputationTokenValue(mockReputationToken.address)

    universe.setController(localFixture.contracts['Controller'].address)
    assert universe.initialize(mockUniverse.address, stringToBytes("5"))
    assert universe.getReputationToken() == mockReputationToken.address
    assert universe.getParentUniverse() == mockUniverse.address
    assert universe.getParentPayoutDistributionHash() == stringToBytes("5")
    assert universe.getForkingMarket() == longToHexString(0)
    assert universe.getForkEndTime() == 0
    assert universe.getTypeName() == stringToBytes('Universe')
    assert universe.getForkEndTime() == 0
    assert universe.getChildUniverse("5") == longToHexString(0)

def test_universe_contains(localFixture, populatedUniverse, mockMarket, chain, mockCash, mockMarketFactory, mockFeeWindow, mockShareToken, mockFeeWindowFactory):
    mockFeeWindow.setStartTime(0)
    assert populatedUniverse.isContainerForFeeWindow(mockFeeWindow.address) == False
    assert populatedUniverse.isContainerForMarket(mockMarket.address) == False
    assert populatedUniverse.isContainerForShareToken(mockShareToken.address) == False

    timestamp = localFixture.contracts["Time"].getTimestamp()
    mockFeeWindowFactory.setCreateFeeWindowValue(mockFeeWindow.address)
    feeWindowId = populatedUniverse.getOrCreateFeeWindowByTimestamp(timestamp)
    mockFeeWindow.setStartTime(timestamp)

    mockMarket.setIsContainerForShareToken(False)

    assert populatedUniverse.isContainerForMarket(mockMarket.address) == False
    assert populatedUniverse.isContainerForShareToken(mockShareToken.address) == False

    mockMarket.setIsContainerForShareToken(True)
    mockMarket.setFeeWindow(mockFeeWindow.address)
    mockShareToken.setMarket(mockMarket.address)

    mockMarketFactory.setMarket(mockMarket.address)
    endTime = localFixture.contracts["Time"].getTimestamp() + 30 * 24 * 60 * 60 # 30 days

    assert populatedUniverse.createYesNoMarket(endTime, 1000, mockCash.address, tester.a0, "topic", "description", "info")
    assert mockMarketFactory.getCreateMarketUniverseValue() == populatedUniverse.address

    assert populatedUniverse.isContainerForFeeWindow(mockFeeWindow.address) == True
    assert populatedUniverse.isContainerForMarket(mockMarket.address) == True
    assert populatedUniverse.isContainerForShareToken(mockShareToken.address) == True

def test_open_interest(localFixture, populatedUniverse):
    multiplier = localFixture.contracts['Constants'].TARGET_REP_MARKET_CAP_MULTIPLIER() / float(localFixture.contracts['Constants'].TARGET_REP_MARKET_CAP_DIVISOR())
    assert populatedUniverse.getTargetRepMarketCapInAttoeth() == 0
    assert populatedUniverse.getOpenInterestInAttoEth() == 0
    populatedUniverse.incrementOpenInterest(20)
    assert populatedUniverse.getTargetRepMarketCapInAttoeth() == 20 * multiplier
    assert populatedUniverse.getOpenInterestInAttoEth() == 20

def test_universe_create_market(localFixture, chain, populatedUniverse, mockMarket, mockMarketFactory, mockCash, mockReputationToken, mockAugur, mockFeeWindowFactory, mockFeeWindow):
    timestamp = localFixture.contracts["Time"].getTimestamp()
    endTimeValue = timestamp + 10
    feePerEthInWeiValue = 10 ** 18
    designatedReporterAddressValue = tester.a2
    mockFeeWindow.setCreateMarket(mockMarket.address)

    # set current fee window
    mockFeeWindowFactory.setCreateFeeWindowValue(mockFeeWindow.address)
    assert populatedUniverse.getOrCreateCurrentFeeWindow() == mockFeeWindow.address

    # set previous fee window
    mockFeeWindowFactory.setCreateFeeWindowValue(mockFeeWindow.address)
    assert populatedUniverse.getOrCreatePreviousFeeWindow() == mockFeeWindow.address

    assert mockAugur.logMarketCreatedCalled() == False
    mockMarketFactory.setMarket(mockMarket.address)

    newMarket = populatedUniverse.createYesNoMarket(endTimeValue, feePerEthInWeiValue, mockCash.address, designatedReporterAddressValue, "topic", "description", "info")

    assert mockMarketFactory.getCreateMarketUniverseValue() == populatedUniverse.address
    assert populatedUniverse.isContainerForMarket(mockMarket.address)
    assert mockAugur.logMarketCreatedCalled() == True
    assert newMarket == mockMarket.address

@fixture(scope="module")
def localSnapshot(fixture, augurInitializedWithMocksSnapshot):
    fixture.resetToSnapshot(augurInitializedWithMocksSnapshot)
    controller = fixture.contracts['Controller']
    mockReputationTokenFactory = fixture.contracts['MockReputationTokenFactory']
    mockFeeWindowFactory = fixture.contracts['MockFeeWindowFactory']
    mockMarketFactory = fixture.contracts['MockMarketFactory']
    mockUniverseFactory = fixture.contracts['MockUniverseFactory']
    controller.registerContract(stringToBytes('MarketFactory'), mockMarketFactory.address, twentyZeros, thirtyTwoZeros)
    controller.registerContract(stringToBytes('ReputationTokenFactory'), mockReputationTokenFactory.address, twentyZeros, thirtyTwoZeros)
    controller.registerContract(stringToBytes('FeeWindowFactory'), mockFeeWindowFactory.address, twentyZeros, thirtyTwoZeros)
    controller.registerContract(stringToBytes('UniverseFactory'), mockUniverseFactory.address, twentyZeros, thirtyTwoZeros)

    mockReputationToken = fixture.contracts['MockReputationToken']
    mockUniverse = fixture.contracts['MockUniverse']

    universe = fixture.upload('../source/contracts/reporting/Universe.sol', 'universe')
    fixture.contracts['populatedUniverse'] = universe
    mockReputationTokenFactory.setCreateReputationTokenValue(mockReputationToken.address)
    universe.setController(fixture.contracts['Controller'].address)
    assert universe.initialize(mockUniverse.address, stringToBytes("5"))

    return fixture.createSnapshot()

@fixture
def localFixture(fixture, localSnapshot):
    fixture.resetToSnapshot(localSnapshot)
    return fixture

@fixture
def chain(localFixture):
    return localFixture.chain

@fixture
def mockFeeWindow(localFixture):
    return localFixture.contracts['MockFeeWindow']

@fixture
def mockReputationToken(localFixture):
    return localFixture.contracts['MockReputationToken']

@fixture
def mockReputationTokenFactory(localFixture):
    return localFixture.contracts['MockReputationTokenFactory']

@fixture
def mockFeeWindowFactory(localFixture):
    return localFixture.contracts['MockFeeWindowFactory']

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
def mockAugur(localFixture):
    return localFixture.contracts['MockAugur']

@fixture
def mockShareToken(localFixture):
    return localFixture.contracts['MockShareToken']

@fixture
def mockCash(localFixture):
    return localFixture.contracts['MockCash']

@fixture
def populatedUniverse(localFixture, mockReputationTokenFactory, mockReputationToken, mockUniverse):
    return localFixture.contracts['populatedUniverse']
