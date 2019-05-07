pragma solidity 0.4.26;

import 'reporting/IMarket.sol';


contract IMailbox {
  function initialize(address _owner, IMarket _market) public returns (bool);
}
