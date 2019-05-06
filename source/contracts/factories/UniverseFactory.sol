pragma solidity 0.4.25;

import 'libraries/Delegator.sol';
import 'IController.sol';
import 'reporting/IUniverse.sol';


contract UniverseFactory {
  function createUniverse(IController _controller) public returns (IUniverse) {
    Delegator _delegator = new Delegator(_controller, "Universe");
    IUniverse _universe = IUniverse(_delegator);
    return _universe;
  }
}
