#!/usr/bin/env python

from ethereum.tools import tester
from ethereum.tools.tester import TransactionFailed
from pytest import fixture, raises
from utils import stringToBytes, EtherDelta, TokenDelta

def test_mailbox_tokens_happy_path(localFixture, mailbox, token):
    # We can send some Tokens to the mailbox
    assert token.faucet(100)

    with TokenDelta(token, 100, mailbox.address, "Token deposit did not work"):
        with TokenDelta(token, -100, tester.a0, "Token deposit did not work"):
            token.transfer(mailbox.address, 100)

    # The mailbox owner can withdraw these tokens
    with TokenDelta(token, 100, tester.a0, "Token withdraw did not work"):
        with TokenDelta(token, -100, mailbox.address, "Token withdraw did not work"):
            mailbox.withdrawTokens(token.address)

def test_mailbox_tokens_failure(localFixture, mailbox, token):
    # We send some Tokens to the mailbox
    assert token.faucet(100)

    with TokenDelta(token, 100, mailbox.address, "Token deposit did not work"):
        with TokenDelta(token, -100, tester.a0, "Token deposit did not work"):
            token.transfer(mailbox.address, 100)

    # Withdrawing as someone other than the owner will fail
    with raises(TransactionFailed):
        mailbox.withdrawTokens(token.address, sender=tester.k1)

@fixture(scope="session")
def localSnapshot(fixture, controllerSnapshot):
    fixture.resetToSnapshot(controllerSnapshot)

    fixture.uploadAugurLite()

    # Upload a token
    fixture.uploadAndAddToController("solidity_test_helpers/StandardTokenHelper.sol")

    # Upload the mailbox
    name = "Mailbox"
    targetName = "MailboxTarget"
    fixture.uploadAndAddToController("../source/contracts/Mailbox.sol", targetName, name)
    fixture.uploadAndAddToController("../source/contracts/libraries/Delegator.sol", name, "delegator", constructorArgs=[fixture.contracts['Controller'].address, stringToBytes(targetName)])
    fixture.contracts[name] = fixture.applySignature(name, fixture.contracts[name].address)
    fixture.contracts[name].initialize(tester.a0)
    return fixture.createSnapshot()

@fixture
def localFixture(fixture, localSnapshot):
    fixture.resetToSnapshot(localSnapshot)
    return fixture

@fixture
def mailbox(localFixture):
    return localFixture.contracts['Mailbox']

@fixture
def token(localFixture):
    return localFixture.contracts['StandardTokenHelper']
