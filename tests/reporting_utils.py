#!/usr/bin/env python

from ethereum.tools import tester
from ethereum.tools.tester import TransactionFailed
from pytest import fixture

def proceedToResolution(fixture, market):
    fixture.contracts["Time"].setTimestamp(market.getEndTime() + 1)
