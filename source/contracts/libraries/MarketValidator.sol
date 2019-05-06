pragma solidity 0.4.25;

import 'reporting/IMarket.sol';
import 'Controlled.sol';


contract MarketValidator is Controlled {
  modifier marketIsLegit(IMarket _market) {
    IUniverse _universe = _market.getUniverse();
    require(controller.getVeilAugur().isKnownUniverse(_universe));
    require(_universe.isContainerForMarket(_market));
    _;
  }
}
