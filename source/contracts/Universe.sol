pragma solidity 0.4.26;

import 'IMarket.sol';
import 'IUniverse.sol';
import 'libraries/DelegationTarget.sol';
import 'libraries/ITyped.sol';
import 'libraries/Initializable.sol';
import 'libraries/math/SafeMathUint256.sol';
import 'libraries/token/ERC20.sol';
import 'factories/MarketFactory.sol';


contract Universe is DelegationTarget, Initializable, ITyped, IUniverse {
  using SafeMathUint256 for uint256;

  mapping(address => bool) private markets;
  ERC20 private denominationToken;

  function initialize(ERC20 _denominationToken) external onlyInGoodTimes beforeInitialized returns (bool) {
    endInitialization();
    denominationToken = _denominationToken;
    return true;
  }

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

  function getDenominationToken() public view returns (ERC20) {
    return denominationToken;
  }

  function createYesNoMarket(uint256 _endTime, uint256 _feeDivisor, ERC20 _denominationToken, address _oracle, bytes32 _topic, string _description, string _extraInfo) public onlyInGoodTimes returns (IMarket _newMarket) {
    require(bytes(_description).length > 0, "Description is empty");
    _newMarket = createMarketInternal(_endTime, _feeDivisor, _denominationToken, _oracle, msg.sender, 2, 10000);
    controller.getAugurLite().logMarketCreated(_topic, _description, _extraInfo, this, _newMarket, msg.sender, 0, 1 ether, IMarket.MarketType.YES_NO);
    return _newMarket;
  }

  function createCategoricalMarket(uint256 _endTime, uint256 _feeDivisor, ERC20 _denominationToken, address _oracle, bytes32[] _outcomes, bytes32 _topic, string _description, string _extraInfo) public onlyInGoodTimes returns (IMarket _newMarket) {
    require(bytes(_description).length > 0, "Description is empty");
    _newMarket = createMarketInternal(_endTime, _feeDivisor, _denominationToken, _oracle, msg.sender, uint256(_outcomes.length), 10000);
    controller.getAugurLite().logMarketCreated(_topic, _description, _extraInfo, this, _newMarket, msg.sender, _outcomes, 0, 1 ether, IMarket.MarketType.CATEGORICAL);
    return _newMarket;
  }

  function createScalarMarket(uint256 _endTime, uint256 _feeDivisor, ERC20 _denominationToken, address _oracle, int256 _minPrice, int256 _maxPrice, uint256 _numTicks, bytes32 _topic, string _description, string _extraInfo) public onlyInGoodTimes returns (IMarket _newMarket) {
    require(bytes(_description).length > 0, "Description is empty");
    require(_minPrice < _maxPrice, "Min price needs to be less than max price");
    require(_numTicks.isMultipleOf(2), "numTicks needs to a multiple of 2");
    _newMarket = createMarketInternal(_endTime, _feeDivisor, _denominationToken, _oracle, msg.sender, 2, _numTicks);
    controller.getAugurLite().logMarketCreated(_topic, _description, _extraInfo, this, _newMarket, msg.sender, _minPrice, _maxPrice, IMarket.MarketType.SCALAR);
    return _newMarket;
  }

  function createMarketInternal(uint256 _endTime, uint256 _feeDivisor, ERC20 _denominationToken, address _oracle, address _sender, uint256 _numOutcomes, uint256 _numTicks) private onlyInGoodTimes returns (IMarket _newMarket) {
    MarketFactory _marketFactory = MarketFactory(controller.lookup("MarketFactory"));
    _newMarket = _marketFactory.createMarket(controller, this, _endTime, _feeDivisor, _denominationToken, _oracle, _sender, _numOutcomes, _numTicks);
    markets[address(_newMarket)] = true;
    return _newMarket;
  }
}
