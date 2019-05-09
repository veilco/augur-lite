pragma solidity 0.4.26;

import 'libraries/Delegator.sol';
import 'libraries/token/ERC20.sol';
import 'IController.sol';
import 'reporting/IUniverse.sol';


contract UniverseFactory {
  function createUniverse(IController _controller, ERC20 _denominationToken) public returns (IUniverse) {
    Delegator _delegator = new Delegator(_controller, "Universe");
    IUniverse _universe = IUniverse(_delegator);
    _universe.initialize(_denominationToken);
    return _universe;
  }
}
