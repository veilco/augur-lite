pragma solidity 0.4.26;

import 'libraries/ITyped.sol';
import 'libraries/token/ERC20.sol';
import 'reporting/IMarket.sol';
import 'trading/IShareToken.sol';


contract IUniverse is ITyped {
  function initialize(ERC20 _denominationToken) external returns (bool);
  function getDenominationToken() public view returns (ERC20);
  function isContainerForMarket(IMarket _shadyTarget) public view returns (bool);
  function isContainerForShareToken(IShareToken _shadyTarget) public view returns (bool);
}
