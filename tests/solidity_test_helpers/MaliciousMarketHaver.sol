pragma solidity 0.4.26;

import 'IMarket.sol';


contract MaliciousMarketHaver {
  IMarket private market;

  function getMarket()  public view returns (IMarket) {
    return market;
  }

  function setMarket(IMarket _market) public returns (bool) {
    market = _market;
    return true;
  }
}
