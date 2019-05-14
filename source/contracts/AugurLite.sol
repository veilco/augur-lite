pragma solidity 0.4.26;

import 'Controlled.sol';
import 'IAugurLite.sol';
import 'IUniverse.sol';
import 'IMarket.sol';
import 'IMailbox.sol';
import 'IShareToken.sol';
import 'libraries/token/ERC20.sol';
import 'factories/UniverseFactory.sol';


// Centralized approval authority and event emissions
contract AugurLite is Controlled, IAugurLite {

  enum TokenType {
    ShareToken
  }

  event MarketCreated(bytes32 indexed topic, string description, string extraInfo, address indexed universe, address market, address indexed marketCreator, bytes32[] outcomes, uint256 marketCreationFee, int256 minPrice, int256 maxPrice, IMarket.MarketType marketType);
  event MarketResolved(address indexed universe, address indexed market);
  event UniverseCreated(address indexed universe, ERC20 denominationToken);
  event CompleteSetsPurchased(address indexed universe, address indexed market, address indexed account, uint256 numCompleteSets);
  event CompleteSetsSold(address indexed universe, address indexed market, address indexed account, uint256 numCompleteSets);
  event TradingProceedsClaimed(address indexed universe, address indexed shareToken, address indexed sender, address market, uint256 numShares, uint256 numPayoutTokens, uint256 finalTokenBalance);
  event TokensTransferred(address indexed universe, address indexed token, address indexed from, address to, uint256 value, TokenType tokenType, address market);
  event TokensMinted(address indexed universe, address indexed token, address indexed target, uint256 amount, TokenType tokenType, address market);
  event TokensBurned(address indexed universe, address indexed token, address indexed target, uint256 amount, TokenType tokenType, address market);
  event MarketTransferred(address indexed universe, address indexed market, address from, address to);
  event MarketMailboxTransferred(address indexed universe, address indexed market, address indexed mailbox, address from, address to);
  event EscapeHatchChanged(bool isOn);
  event TimestampSet(uint256 newTimestamp);

  mapping(address => bool) private universes;

  //
  // Universe
  //

  function createUniverse(ERC20 _denominationToken) public returns (IUniverse) {
    UniverseFactory _universeFactory = UniverseFactory(controller.lookup("UniverseFactory"));
    IUniverse _newUniverse = _universeFactory.createUniverse(controller, _denominationToken);
    universes[_newUniverse] = true;
    emit UniverseCreated(_newUniverse, _denominationToken);
    return _newUniverse;
  }

  function isKnownUniverse(IUniverse _universe) public view returns (bool) {
    return universes[_universe];
  }

  //
  // Transfer
  //

  function trustedTransfer(ERC20 _token, address _from, address _to, uint256 _amount) public onlyWhitelistedCallers returns (bool) {
    require(_amount > 0, "Transfer amount needs to be greater than 0");
    require(_token.transferFrom(_from, _to, _amount), "Transfer failed");
    return true;
  }

  //
  // Logging
  //

  // This signature is intended for the categorical market creation. We use two signatures for the same event because of stack depth issues which can be circumvented by maintaining order of paramaters
  function logMarketCreated(bytes32 _topic, string _description, string _extraInfo, IUniverse _universe, address _market, address _marketCreator, bytes32[] _outcomes, int256 _minPrice, int256 _maxPrice, IMarket.MarketType _marketType) public returns (bool) {
    require(isKnownUniverse(_universe), "The universe is not known");
    require(_universe == IUniverse(msg.sender), "Sender is not the universe contract");
    emit MarketCreated(_topic, _description, _extraInfo, _universe, _market, _marketCreator, _outcomes, 0, _minPrice, _maxPrice, _marketType);
    return true;
  }

  // This signature is intended for yesNo and scalar market creation. See function comment above for explanation.
  function logMarketCreated(bytes32 _topic, string _description, string _extraInfo, IUniverse _universe, address _market, address _marketCreator, int256 _minPrice, int256 _maxPrice, IMarket.MarketType _marketType) public returns (bool) {
    require(isKnownUniverse(_universe), "The universe is not known");
    require(_universe == IUniverse(msg.sender), "Sender is not the universe contract");
    emit MarketCreated(_topic, _description, _extraInfo, _universe, _market, _marketCreator, new bytes32[](0), 0, _minPrice, _maxPrice, _marketType);
    return true;
  }

  function logMarketResolved(IUniverse _universe) public returns (bool) {
    require(isKnownUniverse(_universe), "The universe is not known");
    IMarket _market = IMarket(msg.sender);
    require(_universe.isContainerForMarket(_market), "Market does not belong to the universe");
    emit MarketResolved(_universe, _market);
    return true;
  }

  function logCompleteSetsPurchased(IUniverse _universe, IMarket _market, address _account, uint256 _numCompleteSets) public onlyWhitelistedCallers returns (bool) {
    emit CompleteSetsPurchased(_universe, _market, _account, _numCompleteSets);
    return true;
  }

  function logCompleteSetsSold(IUniverse _universe, IMarket _market, address _account, uint256 _numCompleteSets) public onlyWhitelistedCallers returns (bool) {
    emit CompleteSetsSold(_universe, _market, _account, _numCompleteSets);
    return true;
  }

  function logTradingProceedsClaimed(IUniverse _universe, address _shareToken, address _sender, address _market, uint256 _numShares, uint256 _numPayoutTokens, uint256 _finalTokenBalance) public onlyWhitelistedCallers returns (bool) {
    emit TradingProceedsClaimed(_universe, _shareToken, _sender, _market, _numShares, _numPayoutTokens, _finalTokenBalance);
    return true;
  }

  function logShareTokensTransferred(IUniverse _universe, address _from, address _to, uint256 _value) public returns (bool) {
    require(isKnownUniverse(_universe), "The universe is not known");
    IShareToken _shareToken = IShareToken(msg.sender);
    require(_universe.isContainerForShareToken(_shareToken), "ShareToken does not belong to the universe");
    emit TokensTransferred(_universe, msg.sender, _from, _to, _value, TokenType.ShareToken, _shareToken.getMarket());
    return true;
  }

  function logShareTokenBurned(IUniverse _universe, address _target, uint256 _amount) public returns (bool) {
    require(isKnownUniverse(_universe), "The universe is not known");
    IShareToken _shareToken = IShareToken(msg.sender);
    require(_universe.isContainerForShareToken(_shareToken), "ShareToken does not belong to the universe");
    emit TokensBurned(_universe, msg.sender, _target, _amount, TokenType.ShareToken, _shareToken.getMarket());
    return true;
  }

  function logShareTokenMinted(IUniverse _universe, address _target, uint256 _amount) public returns (bool) {
    require(isKnownUniverse(_universe), "The universe is not known");
    IShareToken _shareToken = IShareToken(msg.sender);
    require(_universe.isContainerForShareToken(_shareToken), "ShareToken does not belong to the universe");
    emit TokensMinted(_universe, msg.sender, _target, _amount, TokenType.ShareToken, _shareToken.getMarket());
    return true;
  }

  function logTimestampSet(uint256 _newTimestamp) public returns (bool) {
    require(msg.sender == controller.lookup("Time"), "Sender is not the Time contract");
    emit TimestampSet(_newTimestamp);
    return true;
  }

  function logMarketTransferred(IUniverse _universe, address _from, address _to) public returns (bool) {
    require(isKnownUniverse(_universe), "The universe is not known");
    IMarket _market = IMarket(msg.sender);
    require(_universe.isContainerForMarket(_market), "Market does not belong to the universe");
    emit MarketTransferred(_universe, _market, _from, _to);
    return true;
  }

  function logMarketMailboxTransferred(IUniverse _universe, IMarket _market, address _from, address _to) public returns (bool) {
    require(isKnownUniverse(_universe), "The universe is not known");
    require(_universe.isContainerForMarket(_market), "Market does not belong to the universe");
    require(IMailbox(msg.sender) == _market.getMarketCreatorMailbox(), "Sender is not the market creator mailbox");
    emit MarketMailboxTransferred(_universe, _market, msg.sender, _from, _to);
    return true;
  }

  function logEscapeHatchChanged(bool _isOn) public returns (bool) {
    require(msg.sender == address(controller), "Sender is not the controller");
    emit EscapeHatchChanged(_isOn);
    return true;
  }
}
