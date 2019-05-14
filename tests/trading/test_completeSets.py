#!/usr/bin/env python

from ethereum.tools import tester
from ethereum.tools.tester import TransactionFailed
from pytest import raises
from utils import bytesToHexString, fix, AssertLog
from constants import YES, NO

def test_publicBuyCompleteSets(contractsFixture, universe, testNetDenominationToken, market):
    completeSets = contractsFixture.contracts['CompleteSets']
    yesShareToken = contractsFixture.applySignature('ShareToken', market.getShareToken(YES))
    noShareToken = contractsFixture.applySignature('ShareToken', market.getShareToken(NO))

    assert not testNetDenominationToken.balanceOf(tester.a1)
    assert not testNetDenominationToken.balanceOf(market.address)
    assert not yesShareToken.totalSupply()
    assert not noShareToken.totalSupply()

    cost = 10 * market.getNumTicks()
    assert testNetDenominationToken.balanceOf(tester.a1) == 0, "Sender's testNetDenominationToken balance should be 0"
    testNetDenominationToken.depositEther(sender=tester.k1, value=cost)
    assert testNetDenominationToken.balanceOf(tester.a1) != 0, "Sender's testNetDenominationToken balance should not be 0"

    completeSetsPurchasedLog = {
        "universe": universe.address,
        "market": market.address,
        "account": bytesToHexString(tester.a1),
        "numCompleteSets": 10
    }
    with AssertLog(contractsFixture, "CompleteSetsPurchased", completeSetsPurchasedLog):
        assert completeSets.publicBuyCompleteSets(market.address, 10, sender=tester.k1)

    assert yesShareToken.balanceOf(tester.a1) == 10, "Should have 10 shares of outcome 1"
    assert noShareToken.balanceOf(tester.a1) == 10, "Should have 10 shares of outcome 2"
    assert testNetDenominationToken.balanceOf(tester.a1) == 0, "Sender's testNetDenominationToken balance should be 0"
    assert testNetDenominationToken.balanceOf(market.address) == cost, "Increase in market's testNetDenominationToken should equal the cost to purchase the complete set"
    assert yesShareToken.totalSupply() == 10, "Increase in yes shares purchased for this market should be 10"
    assert noShareToken.totalSupply() == 10, "Increase in yes shares purchased for this market should be 10"

def test_publicBuyCompleteSets_failure(contractsFixture, universe, testNetDenominationToken, market):
    completeSets = contractsFixture.contracts['CompleteSets']

    amount = 10
    cost = 10 * market.getNumTicks()
    testNetDenominationToken.depositEther(value=cost, sender=tester.k1)

    # Permissions exceptions
    with raises(TransactionFailed):
        completeSets.buyCompleteSets(tester.a1, market.address, amount, sender=tester.k1)

    # buyCompleteSets exceptions
    with raises(TransactionFailed):
        completeSets.publicBuyCompleteSets(tester.a1, amount, sender=tester.k1)

def test_publicSellCompleteSets(contractsFixture, universe, testNetDenominationToken, market):
    completeSets = contractsFixture.contracts['CompleteSets']
    yesShareToken = contractsFixture.applySignature('ShareToken', market.getShareToken(YES))
    noShareToken = contractsFixture.applySignature('ShareToken', market.getShareToken(NO))
    testNetDenominationToken.transfer(0, testNetDenominationToken.balanceOf(tester.a9), sender = tester.k9)

    assert not testNetDenominationToken.balanceOf(tester.a0)
    assert not testNetDenominationToken.balanceOf(tester.a1)
    assert not testNetDenominationToken.balanceOf(market.address)
    assert not yesShareToken.totalSupply()
    assert not noShareToken.totalSupply()

    a = contractsFixture.chain.head_state.get_balance(tester.a1)
    cost = 10 * market.getNumTicks()
    testNetDenominationToken.depositEther(sender=tester.k1, value=cost)
    assert testNetDenominationToken.balanceOf(tester.a1) != 0, "Sender's testNetDenominationToken balance should not be 0"

    b = contractsFixture.chain.head_state.get_balance(tester.a1)
    completeSets.publicBuyCompleteSets(market.address, 10, sender = tester.k1)

    initialTester1DenominationTokenBalance = testNetDenominationToken.balanceOf(tester.a1)

    completeSetsSoldLog = {
        "universe": universe.address,
        "market": market.address,
        "account": bytesToHexString(tester.a1),
        "numCompleteSets": 9
    }
    with AssertLog(contractsFixture, "CompleteSetsSold", completeSetsSoldLog):
        result = completeSets.publicSellCompleteSets(market.address, 9, sender=tester.k1)

    assert yesShareToken.balanceOf(tester.a1) == 1, "Should have 1 share of outcome yes"
    assert noShareToken.balanceOf(tester.a1) == 1, "Should have 1 share of outcome no"
    assert yesShareToken.totalSupply() == 1
    assert noShareToken.totalSupply() == 1
    assert testNetDenominationToken.balanceOf(market.getMarketCreatorMailbox()) == 900
    assert testNetDenominationToken.balanceOf(tester.a1) == (initialTester1DenominationTokenBalance + 88200 + testNetDenominationToken.balanceOf(market.getMarketCreatorMailbox()))
    assert testNetDenominationToken.balanceOf(market.address) == 10000

def test_publicSellCompleteSets_failure(contractsFixture, universe, testNetDenominationToken, market):
    completeSets = contractsFixture.contracts['CompleteSets']

    cost = 10 * market.getNumTicks()
    assert testNetDenominationToken.balanceOf(tester.a1) == 0, "Sender's testNetDenominationToken balance should be 0"
    testNetDenominationToken.depositEther(sender=tester.k1, value=cost)
    assert testNetDenominationToken.balanceOf(tester.a1) != 0, "Sender's testNetDenominationToken balance should not be 0"

    # Permissions exceptions
    with raises(TransactionFailed):
        completeSets.sellCompleteSets(tester.a1, market.address, 10, sender=tester.k1)

    # sellCompleteSets exceptions
    with raises(TransactionFailed):
        completeSets.publicSellCompleteSets(market.address, 10 + 1, sender=tester.k1)

def test_maliciousMarket(contractsFixture, universe, testNetDenominationToken, market):
    completeSets = contractsFixture.contracts['CompleteSets']
    maliciousMarket = contractsFixture.upload('solidity_test_helpers/MaliciousMarket.sol', 'maliciousMarket', constructorArgs=[market.address])

    with raises(TransactionFailed):
        completeSets.publicBuyCompleteSets(maliciousMarket.address, 10**18, sender = tester.k1)
