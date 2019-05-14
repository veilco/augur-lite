pragma solidity 0.4.26;

import 'IMarket.sol';
import 'IUniverse.sol';
import 'libraries/ITyped.sol';
import 'libraries/Initializable.sol';
import 'libraries/math/SafeMathUint256.sol';
import 'factories/MarketFactory.sol';
import 'Controller.sol';
import 'libraries/Initializable.sol';
import 'TEST/MockVariableSupplyToken.sol';
import 'libraries/token/ERC20.sol';


contract MockUniverse is Initializable, IUniverse {
  using SafeMathUint256 for uint256;

  bool private setIsContainerForMarketValue;
  bool private setIsContainerForShareTokenValue;
  MarketFactory private marketFactory;
  Controller private controller;
  bool private addMarketToWasCalledValue;
  ERC20 private denominationToken;
  /*
  * setters to feed the getters and impl of IUniverse
  */
  function reset() public {
    addMarketToWasCalledValue = false;
  }

  function setIsContainerForMarket(bool _setIsContainerForMarketValue) public {
    setIsContainerForMarketValue = _setIsContainerForMarketValue;
  }

  function setIsContainerForShareToken(bool _setIsContainerForShareTokenValue) public {
    setIsContainerForShareTokenValue = _setIsContainerForShareTokenValue;
  }

  function setDenominationToken(ERC20 _denominationToken) public {
    denominationToken = _denominationToken;
  }

  /*
  * Impl of IUniverse and ITyped
   */
  function getTypeName() public view returns (bytes32) {
    return "Universe";
  }

  function initialize(ERC20 _denominationToken) external returns (bool) {
    denominationToken = _denominationToken;
    return true;
  }

  function getDenominationToken() public view returns (ERC20) {
    return denominationToken;
  }

  function isContainerForMarket(IMarket _shadyTarget) public view returns (bool) {
    return setIsContainerForMarketValue;
  }

  function isContainerForShareToken(IShareToken _shadyTarget) public view returns (bool) {
    return setIsContainerForShareTokenValue;
  }

  function createYesNoMarket(uint256 _endTime, uint256 _feePerEthInWei, MockVariableSupplyToken _denominationToken, address _designatedReporterAddress, bytes32 _topic, string _description, string _extraInfo) public returns (IMarket _newMarket) {
    _newMarket = createMarketInternal(_endTime, _feePerEthInWei, _denominationToken, _designatedReporterAddress, msg.sender, 2, 10000);
    return _newMarket;
  }

  function createCategoricalMarket(uint256 _endTime, uint256 _feePerEthInWei, MockVariableSupplyToken _denominationToken, address _designatedReporterAddress, bytes32[] _outcomes, bytes32 _topic, string _description, string _extraInfo) public returns (IMarket _newMarket) {
    _newMarket = createMarketInternal(_endTime, _feePerEthInWei, _denominationToken, _designatedReporterAddress, msg.sender, uint256(_outcomes.length), 10000);
    return _newMarket;
  }

  function createScalarMarket(uint256 _endTime, uint256 _feePerEthInWei, MockVariableSupplyToken _denominationToken, address _designatedReporterAddress, int256 _minPrice, int256 _maxPrice, uint256 _numTicks, bytes32 _topic, string _description, string _extraInfo) public returns (IMarket _newMarket) {
    _newMarket = createMarketInternal(_endTime, _feePerEthInWei, _denominationToken, _designatedReporterAddress, msg.sender, 2, _numTicks);
    return _newMarket;
  }

  function createMarketInternal(uint256 _endTime, uint256 _feePerEthInWei, MockVariableSupplyToken _denominationToken, address _designatedReporterAddress, address _sender, uint256 _numOutcomes, uint256 _numTicks) private returns (IMarket _newMarket) {
    _newMarket = marketFactory.createMarket(controller, this, _endTime, _feePerEthInWei, _denominationToken, _designatedReporterAddress, _sender, _numOutcomes, _numTicks);
    return _newMarket;
  }
}
