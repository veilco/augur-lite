pragma solidity 0.4.26;

import 'IMarket.sol';
import 'IUniverse.sol';
import 'Controlled.sol';


contract MarketValidator is Controlled {
  modifier marketIsLegit(IMarket _market) {
    IUniverse _universe = _market.getUniverse();
    require(controller.getAugurLite().isKnownUniverse(_universe), "The universe is not known");
    require(_universe.isContainerForMarket(_market), "Market does not belong to the universe");
    _;
  }
}
