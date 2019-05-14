#!/usr/bin/env python

from datetime import timedelta
from ethereum.tools import tester
from ethereum.tools.tester import TransactionFailed
from pytest import raises, fixture, mark
from utils import fix, AssertLog, bytesToHexString, EtherDelta, TokenDelta
from constants import YES, NO


def captureLog(contract, logs, message):
    translated = contract.translator.listen(message)
    if not translated: return
    logs.append(translated)

def acquireLongShares(kitchenSinkFixture, testNetDenominationToken, market, outcome, amount, approvalAddress, sender):
    if amount == 0: return

    shareToken = kitchenSinkFixture.applySignature('ShareToken', market.getShareToken(outcome))
    completeSets = kitchenSinkFixture.contracts['CompleteSets']
    cost = amount * market.getNumTicks()
    testNetDenominationToken.depositEther(sender=sender, value=cost)

    assert completeSets.publicBuyCompleteSets(market.address, amount, sender = sender)
    assert shareToken.approve(approvalAddress, amount, sender = sender)
    for otherOutcome in range(0, market.getNumberOfOutcomes()):
        if otherOutcome == outcome: continue
        otherShareToken = kitchenSinkFixture.applySignature('ShareToken', market.getShareToken(otherOutcome))
        assert otherShareToken.transfer(0, amount, sender = sender)

def acquireShortShareSet(kitchenSinkFixture, testNetDenominationToken, market, outcome, amount, approvalAddress, sender):
    if amount == 0: return

    cost = amount * market.getNumTicks()
    testNetDenominationToken.depositEther(sender=sender, value=cost)

    shareToken = kitchenSinkFixture.applySignature('ShareToken', market.getShareToken(outcome))
    completeSets = kitchenSinkFixture.contracts['CompleteSets']

    assert completeSets.publicBuyCompleteSets(market.address, amount, sender = sender)
    assert shareToken.transfer(0, amount, sender = sender)
    for otherOutcome in range(0, market.getNumberOfOutcomes()):
        if otherOutcome == outcome: continue
        otherShareToken = kitchenSinkFixture.applySignature('ShareToken', market.getShareToken(otherOutcome))
        assert otherShareToken.approve(approvalAddress, amount, sender = sender)

def resolveMarket(fixture, market, payoutNumerators, invalid=False):
    # set timestamp to after market end
    fixture.contracts["Time"].setTimestamp(market.getEndTime() + 1)
    # have tester.a0 submit designated report
    market.resolve(payoutNumerators, invalid)
    fixture.contracts["Time"].setTimestamp(market.getResolutionTime() + 1)

def test_helpers(kitchenSinkFixture, scalarMarket):
    market = scalarMarket
    claimTradingProceeds = kitchenSinkFixture.contracts['ClaimTradingProceeds']
    resolveMarket(kitchenSinkFixture, market, [0,40*10**4])

    assert claimTradingProceeds.calculateCreatorFee(market.address, fix('3')) == fix('0.03')
    assert claimTradingProceeds.calculateProceeds(market.address, YES, 7) == 7 * market.getNumTicks()
    assert claimTradingProceeds.calculateProceeds(market.address, NO, fix('11')) == fix('0')
    (proceeds, shareholderShare, creatorShare) = claimTradingProceeds.divideUpWinnings(market.address, YES, 13)
    assert proceeds == 13.0 * market.getNumTicks()
    assert creatorShare == 13.0 * market.getNumTicks() * 0.01
    assert shareholderShare == 13.0 * market.getNumTicks() * 0.99

def test_redeem_shares_in_yesNo_market(kitchenSinkFixture, universe, testNetDenominationToken, market):
    claimTradingProceeds = kitchenSinkFixture.contracts['ClaimTradingProceeds']
    yesShareToken = kitchenSinkFixture.applySignature('ShareToken', market.getShareToken(YES))
    noShareToken = kitchenSinkFixture.applySignature('ShareToken', market.getShareToken(NO))
    expectedValue = 1 * market.getNumTicks()
    expectedMarketCreatorFees = expectedValue / market.getMarketCreatorSettlementFeeDivisor()
    expectedSettlementFees = expectedMarketCreatorFees
    expectedPayout = long(expectedValue - expectedSettlementFees)

    print testNetDenominationToken.balanceOf(tester.a1)
    # get YES shares with a1
    acquireLongShares(kitchenSinkFixture, testNetDenominationToken, market, YES, 1, claimTradingProceeds.address, sender = tester.k1)
    # get NO shares with a2
    acquireShortShareSet(kitchenSinkFixture, testNetDenominationToken, market, YES, 1, claimTradingProceeds.address, sender = tester.k2)
    resolveMarket(kitchenSinkFixture, market, [0,10**4])

    initialLongHolderToken = testNetDenominationToken.balanceOf(tester.a1)
    initialShortHolderToken = testNetDenominationToken.balanceOf(tester.a2)

    tradingProceedsClaimedLog = {
        'market': market.address,
        'shareToken': yesShareToken.address,
        'numPayoutTokens': expectedPayout,
        'numShares': 1,
        'sender': bytesToHexString(tester.a1),
        'finalTokenBalance': initialLongHolderToken + expectedPayout
    }

    with TokenDelta(testNetDenominationToken, expectedMarketCreatorFees, market.getMarketCreatorMailbox(), "Market creator fees not paid"):
        # redeem shares with a1
        with AssertLog(kitchenSinkFixture, "TradingProceedsClaimed", tradingProceedsClaimedLog):
            claimTradingProceeds.claimTradingProceeds(market.address, tester.a1)

        # redeem shares with a2
        claimTradingProceeds.claimTradingProceeds(market.address, tester.a2)

    # assert a1 ends up with testNetDenominationToken (minus fees) and a2 does not
    assert testNetDenominationToken.balanceOf(tester.a1) == (initialLongHolderToken + expectedPayout)
    assert testNetDenominationToken.balanceOf(tester.a2) == initialShortHolderToken
    assert yesShareToken.balanceOf(tester.a1) == 0
    assert yesShareToken.balanceOf(tester.a2) == 0
    assert noShareToken.balanceOf(tester.a1) == 0
    assert noShareToken.balanceOf(tester.a2) == 0

@mark.parametrize('isInvalid', [
    True,
    False
])
def test_redeem_shares_in_categorical_market(isInvalid, kitchenSinkFixture, universe, testNetDenominationToken, categoricalMarket):
    market = categoricalMarket
    claimTradingProceeds = kitchenSinkFixture.contracts['ClaimTradingProceeds']
    shareToken2 = kitchenSinkFixture.applySignature('ShareToken', market.getShareToken(2))
    shareToken1 = kitchenSinkFixture.applySignature('ShareToken', market.getShareToken(1))
    shareToken0 = kitchenSinkFixture.applySignature('ShareToken', market.getShareToken(0))
    numTicks = market.getNumTicks()
    expectedValue = numTicks if not isInvalid else numTicks / 3
    expectedSettlementFees = expectedValue * 0.01
    expectedPayout = long(expectedValue - expectedSettlementFees)
    if (isInvalid):
        expectedPayout += 1 # rounding errors

    # get long shares with a1
    acquireLongShares(kitchenSinkFixture, testNetDenominationToken, market, 2, 1, claimTradingProceeds.address, sender = tester.k1)
    # get short shares with a2
    acquireShortShareSet(kitchenSinkFixture, testNetDenominationToken, market, 2, 1, claimTradingProceeds.address, sender = tester.k2)

    if (isInvalid):
        invalidPayout = numTicks / 3
        resolveMarket(kitchenSinkFixture, market, [invalidPayout, invalidPayout, invalidPayout], True)
    else:
        resolveMarket(kitchenSinkFixture, market, [0, 0, numTicks])

    # redeem shares with a1
    initialLongHolderToken = testNetDenominationToken.balanceOf(tester.a1)
    claimTradingProceeds.claimTradingProceeds(market.address, tester.a1)
    # redeem shares with a2
    initialShortHolderToken = testNetDenominationToken.balanceOf(tester.a2)
    claimTradingProceeds.claimTradingProceeds(market.address, tester.a2)

    # assert both accounts are paid (or not paid) accordingly
    assert testNetDenominationToken.balanceOf(tester.a1) == (initialLongHolderToken + expectedPayout)
    shortHolderPayout = 2 * expectedPayout if isInvalid else 0
    assert testNetDenominationToken.balanceOf(tester.a2) == (initialShortHolderToken + shortHolderPayout)
    assert shareToken2.balanceOf(tester.a1) == 0
    assert shareToken2.balanceOf(tester.a2) == 0
    assert shareToken1.balanceOf(tester.a1) == 0
    assert shareToken1.balanceOf(tester.a2) == 0
    assert shareToken0.balanceOf(tester.a1) == 0
    assert shareToken0.balanceOf(tester.a2) == 0

def test_redeem_shares_in_scalar_market(kitchenSinkFixture, universe, testNetDenominationToken, scalarMarket):
    market = scalarMarket
    claimTradingProceeds = kitchenSinkFixture.contracts['ClaimTradingProceeds']
    yesShareToken = kitchenSinkFixture.applySignature('ShareToken', market.getShareToken(YES))
    noShareToken = kitchenSinkFixture.applySignature('ShareToken', market.getShareToken(NO))
    expectedValue = 1 * market.getNumTicks()
    expectedSettlementFees = expectedValue * 0.01
    expectedPayout = long(expectedValue - expectedSettlementFees)

    # get YES shares with a1
    acquireLongShares(kitchenSinkFixture, testNetDenominationToken, market, YES, 1, claimTradingProceeds.address, sender = tester.k1)
    # get NO shares with a2
    acquireShortShareSet(kitchenSinkFixture, testNetDenominationToken, market, YES, 1, claimTradingProceeds.address, sender = tester.k2)
    resolveMarket(kitchenSinkFixture, market, [10**5, 3*10**5])

    # redeem shares with a1
    initialLongHolderToken = testNetDenominationToken.balanceOf(tester.a1)
    claimTradingProceeds.claimTradingProceeds(market.address, tester.a1)
    # redeem shares with a2
    initialShortHolderToken = testNetDenominationToken.balanceOf(tester.a2)
    claimTradingProceeds.claimTradingProceeds(market.address, tester.a2)

    # assert a1 ends up with testNetDenominationToken (minus fees) and a2 does not
    assert testNetDenominationToken.balanceOf(tester.a1) == (initialLongHolderToken + expectedPayout * 3 / 4)
    assert testNetDenominationToken.balanceOf(tester.a2) == (initialShortHolderToken + expectedPayout * 1 / 4)
    assert yesShareToken.balanceOf(tester.a1) == 0
    assert yesShareToken.balanceOf(tester.a2) == 0
    assert noShareToken.balanceOf(tester.a1) == 0
    assert noShareToken.balanceOf(tester.a2) == 0

def test_reedem_failure(kitchenSinkFixture, testNetDenominationToken, market):
    claimTradingProceeds = kitchenSinkFixture.contracts['ClaimTradingProceeds']

    # get YES shares with a1
    acquireLongShares(kitchenSinkFixture, testNetDenominationToken, market, YES, 1, claimTradingProceeds.address, sender = tester.k1)
    # get NO shares with a2
    acquireShortShareSet(kitchenSinkFixture, testNetDenominationToken, market, YES, 1, claimTradingProceeds.address, sender = tester.k2)
    # set timestamp to after market end
    kitchenSinkFixture.contracts["Time"].setTimestamp(market.getEndTime() + 1)

    # market not finalized
    with raises(TransactionFailed):
        claimTradingProceeds.claimTradingProceeds(market.address, tester.a1)

    # have tester.a0 resolve (75% high, 25% low, range -10*10^18 to 30*10^18)
    market.resolve([0, 10**4], False)
    # set timestamp to after market end
    kitchenSinkFixture.contracts["Time"].setTimestamp(market.getResolutionTime() + 1)
    # validate that everything else is OK
    assert claimTradingProceeds.claimTradingProceeds(market.address, tester.a1)
