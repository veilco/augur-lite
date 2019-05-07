pragma solidity 0.4.26;

import 'libraries/ITyped.sol';
import 'reporting/IMarket.sol';
import 'trading/IShareToken.sol';


contract IUniverse is ITyped {
  function getOpenInterestInAttoEth() public view returns (uint256);
  function isContainerForMarket(IMarket _shadyTarget) public view returns (bool);
  function isContainerForShareToken(IShareToken _shadyTarget) public view returns (bool);
  function decrementOpenInterest(uint256 _amount) public returns (bool);
  function decrementOpenInterestFromMarket(uint256 _amount) public returns (bool);
  function incrementOpenInterest(uint256 _amount) public returns (bool);
  function incrementOpenInterestFromMarket(uint256 _amount) public returns (bool);
}
