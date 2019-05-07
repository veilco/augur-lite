pragma solidity 0.4.26;

import 'reporting/IUniverse.sol';
import 'libraries/DelegationTarget.sol';
import 'libraries/ITyped.sol';
import 'factories/MarketFactory.sol';
import 'reporting/IMarket.sol';
import 'libraries/math/SafeMathUint256.sol';
import 'libraries/token/ERC20.sol';


contract Universe is DelegationTarget, ITyped, IUniverse {
  using SafeMathUint256 for uint256;

  mapping(address => bool) private markets;
  uint256 private openInterestInAttoEth;

  function getTypeName() public view returns (bytes32) {
    return "Universe";
  }

  function isContainerForMarket(IMarket _shadyMarket) public view returns (bool) {
    return markets[address(_shadyMarket)];
  }

  function isContainerForShareToken(IShareToken _shadyShareToken) public view returns (bool) {
    IMarket _shadyMarket = _shadyShareToken.getMarket();
    if (_shadyMarket == address(0)) {
      return false;
    }
    if (!isContainerForMarket(_shadyMarket)) {
      return false;
    }
    IMarket _legitMarket = _shadyMarket;
    return _legitMarket.isContainerForShareToken(_shadyShareToken);
  }

  function decrementOpenInterest(uint256 _amount) public onlyInGoodTimes onlyWhitelistedCallers returns (bool) {
    openInterestInAttoEth = openInterestInAttoEth.sub(_amount);
    return true;
  }

  function decrementOpenInterestFromMarket(uint256 _amount) public returns (bool) {
    require(isContainerForMarket(IMarket(msg.sender)));
    openInterestInAttoEth = openInterestInAttoEth.sub(_amount);
    return true;
  }

  function incrementOpenInterest(uint256 _amount) public onlyInGoodTimes onlyWhitelistedCallers returns (bool) {
    openInterestInAttoEth = openInterestInAttoEth.add(_amount);
    return true;
  }

  function incrementOpenInterestFromMarket(uint256 _amount) public onlyInGoodTimes returns (bool) {
    require(isContainerForMarket(IMarket(msg.sender)));
    openInterestInAttoEth = openInterestInAttoEth.add(_amount);
    return true;
  }

  function getOpenInterestInAttoEth() public view returns (uint256) {
    return openInterestInAttoEth;
  }

  function createYesNoMarket(uint256 _endTime, uint256 _feePerEthInWei, ERC20 _denominationToken, address _oracle, bytes32 _topic, string _description, string _extraInfo) public onlyInGoodTimes payable returns (IMarket _newMarket) {
    require(bytes(_description).length > 0);
    _newMarket = createMarketInternal(_endTime, _feePerEthInWei, _denominationToken, _oracle, msg.sender, 2, 10000);
    controller.getAugurLite().logMarketCreated(_topic, _description, _extraInfo, this, _newMarket, msg.sender, 0, 1 ether, IMarket.MarketType.YES_NO);
    return _newMarket;
  }

  function createCategoricalMarket(uint256 _endTime, uint256 _feePerEthInWei, ERC20 _denominationToken, address _oracle, bytes32[] _outcomes, bytes32 _topic, string _description, string _extraInfo) public onlyInGoodTimes payable returns (IMarket _newMarket) {
    require(bytes(_description).length > 0);
    _newMarket = createMarketInternal(_endTime, _feePerEthInWei, _denominationToken, _oracle, msg.sender, uint256(_outcomes.length), 10000);
    controller.getAugurLite().logMarketCreated(_topic, _description, _extraInfo, this, _newMarket, msg.sender, _outcomes, 0, 1 ether, IMarket.MarketType.CATEGORICAL);
    return _newMarket;
  }

  function createScalarMarket(uint256 _endTime, uint256 _feePerEthInWei, ERC20 _denominationToken, address _oracle, int256 _minPrice, int256 _maxPrice, uint256 _numTicks, bytes32 _topic, string _description, string _extraInfo) public onlyInGoodTimes payable returns (IMarket _newMarket) {
    require(bytes(_description).length > 0);
    require(_minPrice < _maxPrice);
    require(_numTicks.isMultipleOf(2));
    _newMarket = createMarketInternal(_endTime, _feePerEthInWei, _denominationToken, _oracle, msg.sender, 2, _numTicks);
    controller.getAugurLite().logMarketCreated(_topic, _description, _extraInfo, this, _newMarket, msg.sender, _minPrice, _maxPrice, IMarket.MarketType.SCALAR);
    return _newMarket;
  }

  function createMarketInternal(uint256 _endTime, uint256 _feePerEthInWei, ERC20 _denominationToken, address _oracle, address _sender, uint256 _numOutcomes, uint256 _numTicks) private onlyInGoodTimes returns (IMarket _newMarket) {
    MarketFactory _marketFactory = MarketFactory(controller.lookup("MarketFactory"));
    _newMarket = _marketFactory.createMarket(controller, this, _endTime, _feePerEthInWei, _denominationToken, _oracle, _sender, _numOutcomes, _numTicks);
    markets[address(_newMarket)] = true;
    return _newMarket;
  }
}
