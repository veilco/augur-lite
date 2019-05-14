pragma solidity 0.4.26;

import 'IMarket.sol';


contract IMailbox {
  function initialize(address _owner, IMarket _market) public returns (bool);
}
