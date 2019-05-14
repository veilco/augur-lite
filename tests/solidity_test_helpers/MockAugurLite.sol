pragma solidity 0.4.26;

import 'Controlled.sol';
import 'libraries/token/ERC20.sol';
import 'IUniverse.sol';
import 'IMarket.sol';
import 'IShareToken.sol';


contract MockAugurLite is Controlled {

  function reset() public {
    logMarketCreatedCalledValue = false;
    logMarketResolvedCalledValue = false;
  }

  function trustedTransfer(ERC20 _token, address _from, address _to, uint256 _amount) public onlyWhitelistedCallers returns (bool) {
    return true;
  }

  //
  // Logging
  //
  bool private logMarketCreatedCalledValue;

  function logMarketCreatedCalled() public returns(bool) {return logMarketCreatedCalledValue;}

  function logMarketCreated(bytes32 _topic, string _description, string _extraInfo, IUniverse _universe, address _market, address _marketCreator, bytes32[] _outcomes, int256 _minPrice, int256 _maxPrice, IMarket.MarketType _marketType) public returns (bool) {
    logMarketCreatedCalledValue = true;
    return true;
  }

  function logMarketCreated(bytes32 _topic, string _description, string _extraInfo, IUniverse _universe, address _market, address _marketCreator, int256 _minPrice, int256 _maxPrice, IMarket.MarketType _marketType) public returns (bool) {
    logMarketCreatedCalledValue = true;
    return true;
  }

  function logMarketResolvedCalled() public returns (bool) { return logMarketResolvedCalledValue; }

  bool private logMarketResolvedCalledValue;

  function logMarketResolved(IUniverse _universe) public returns (bool) {
    logMarketResolvedCalledValue = true;
    return true;
  }

  function logCompleteSetsPurchased(IUniverse _universe, IMarket _market, address _account, uint256 _numCompleteSets) public onlyWhitelistedCallers returns (bool) {
    return true;
  }

  function logCompleteSetsSold(IUniverse _universe, IMarket _market, address _account, uint256 _numCompleteSets) public onlyWhitelistedCallers returns (bool) {
    return true;
  }

  function logProceedsClaimed(IUniverse _universe, address _shareToken, address _sender, address _market, uint256 _numShares, uint256 _numPayoutTokens, uint256 _finalTokenBalance) public onlyWhitelistedCallers returns (bool) {
    return true;
  }

  function logShareTokenBurned(IUniverse _universe, address _target, uint256 _amount) public returns (bool) {
    return true;
  }

  function logShareTokenMinted(IUniverse _universe, address _target, uint256 _amount) public returns (bool) {
    return true;
  }

  bool private logUniverseCreatedCalledValue;

  function logUniverseCreatedCalled() public returns(bool) { return logUniverseCreatedCalledValue;}

  function logUniverseCreated(IUniverse _childUniverse, uint256[] _payoutNumerators, bool _invalid) public returns (bool) {
    logUniverseCreatedCalledValue = true;
    return true;
  }

  function logShareTokensTransferred(IUniverse _universe, address _from, address _to, uint256 _value) public returns (bool) {
    return true;
  }

  function logTimestampSet(uint256 _newTimestamp) public returns (bool) {
    return true;
  }

  function logMarketTransferred(IUniverse _universe, address _from, address _to) public returns (bool) {
    return true;
  }

  function logMarketMailboxTransferred(IUniverse _universe, IMarket _market, address _from, address _to) public returns (bool) {
    return true;
  }
}
