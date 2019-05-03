pragma solidity 0.4.25;


import 'libraries/Delegator.sol';
import 'reporting/IMarket.sol';
import 'libraries/token/ERC20.sol';
import 'IController.sol';


contract MarketFactory {
    function createMarket(IController _controller, IUniverse _universe, uint256 _endTime, uint256 _feePerEthInWei, ERC20 _denominationToken, address _designatedReporterAddress, address _sender, uint256 _numOutcomes, uint256 _numTicks) public returns (IMarket _market) {
        Delegator _delegator = new Delegator(_controller, "Market");
        _market = IMarket(_delegator);
        _market.initialize(_universe, _endTime, _feePerEthInWei, _denominationToken, _designatedReporterAddress, _sender, _numOutcomes, _numTicks);
        return _market;
    }
}
