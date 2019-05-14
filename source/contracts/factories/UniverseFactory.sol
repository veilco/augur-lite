pragma solidity 0.4.26;

import 'IController.sol';
import 'IUniverse.sol';
import 'libraries/Delegator.sol';
import 'libraries/token/ERC20.sol';


contract UniverseFactory {
  function createUniverse(IController _controller, ERC20 _denominationToken) public returns (IUniverse) {
    Delegator _delegator = new Delegator(_controller, "Universe");
    IUniverse _universe = IUniverse(_delegator);
    _universe.initialize(_denominationToken);
    return _universe;
  }
}
