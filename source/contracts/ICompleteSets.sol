pragma solidity 0.4.26;

import 'IMarket.sol';


contract ICompleteSets {
  function buyCompleteSets(address _sender, IMarket _market, uint256 _amount) external returns (bool);
  function sellCompleteSets(address _sender, IMarket _market, uint256 _amount) external returns (bool);
}
