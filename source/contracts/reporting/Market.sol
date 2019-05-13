pragma solidity 0.4.26;

import 'reporting/IMarket.sol';
import 'libraries/DelegationTarget.sol';
import 'libraries/ITyped.sol';
import 'libraries/Initializable.sol';
import 'libraries/Ownable.sol';
import 'reporting/IUniverse.sol';
import 'libraries/token/ERC20.sol';
import 'trading/IShareToken.sol';
import 'factories/ShareTokenFactory.sol';
import 'libraries/math/SafeMathUint256.sol';
import 'libraries/math/SafeMathInt256.sol';
import 'reporting/IMailbox.sol';
import 'factories/MailboxFactory.sol';


contract Market is DelegationTarget, ITyped, Initializable, Ownable, IMarket {
  using SafeMathUint256 for uint256;
  using SafeMathInt256 for int256;

  // Constants
  uint256 private constant MAX_FEE_PER_ETH_IN_ATTOETH = 1 ether / 2;
  uint256 private constant APPROVAL_AMOUNT = 2 ** 256 - 1;
  address private constant NULL_ADDRESS = address(0);
  uint256 private constant MIN_OUTCOMES = 2;
  uint256 private constant MAX_OUTCOMES = 8;

  // Contract Refs
  IUniverse private universe;
  ERC20 private denominationToken;

  // Attributes
  uint256 private numTicks;
  uint256 private feeDivisor;
  uint256 private endTime;
  uint256 private numOutcomes;
  uint256 private resolutionTime;
  address private oracle;
  bool private invalid;
  IMailbox private marketCreatorMailbox;
  uint256[] private payoutNumerators;
  IShareToken[] private shareTokens;

  function initialize(IUniverse _universe, uint256 _endTime, uint256 _feePerEthInAttoeth, ERC20 _denominationToken, address _oracle, address _creator, uint256 _numOutcomes, uint256 _numTicks) public onlyInGoodTimes beforeInitialized returns (bool _success) {
    endInitialization();
    require(MIN_OUTCOMES <= _numOutcomes && _numOutcomes <= MAX_OUTCOMES);
    require(_numTicks > 0);
    require(_oracle != NULL_ADDRESS);
    require((_numTicks >= _numOutcomes));
    require(_feePerEthInAttoeth <= MAX_FEE_PER_ETH_IN_ATTOETH);
    require(_creator != NULL_ADDRESS);
    require(controller.getTimestamp() < _endTime);
    require(IUniverse(_universe).getDenominationToken() == _denominationToken);

    universe = _universe;
    owner = _creator;
    endTime = _endTime;
    numOutcomes = _numOutcomes;
    numTicks = _numTicks;
    feeDivisor = _feePerEthInAttoeth == 0 ? 0 : 1 ether / _feePerEthInAttoeth;
    denominationToken = _denominationToken;
    oracle = _oracle;
    marketCreatorMailbox = MailboxFactory(controller.lookup("MailboxFactory")).createMailbox(controller, owner, this);
    for (uint256 _outcome = 0; _outcome < numOutcomes; _outcome++) {
      shareTokens.push(createShareToken(_outcome));
    }
    approveSpenders();
    return true;
  }

  function createShareToken(uint256 _outcome) private onlyInGoodTimes returns (IShareToken) {
    return ShareTokenFactory(controller.lookup("ShareTokenFactory")).createShareToken(controller, this, _outcome);
  }

  // This will need to be called manually for each open market if a spender contract is updated
  function approveSpenders() public onlyInGoodTimes returns (bool) {
    require(denominationToken.approve(controller.lookup("CompleteSets"), APPROVAL_AMOUNT));
    require(denominationToken.approve(controller.lookup("ClaimTradingProceeds"), APPROVAL_AMOUNT));
    return true;
  }

  function resolve(uint256[] _payoutNumerators, bool _invalid) public onlyInGoodTimes returns (bool) {
    uint256 _timestamp = controller.getTimestamp();
    require(!isResolved());
    require(_timestamp > endTime);
    require(msg.sender == getOracle());
    require(verifyResolutionInformation(_payoutNumerators, _invalid));

    resolutionTime = _timestamp;
    payoutNumerators = _payoutNumerators;
    invalid = _invalid;
    controller.getAugurLite().logMarketResolved(universe);
    return true;
  }

  function getMarketCreatorSettlementFeeDivisor() public view returns (uint256) {
    return feeDivisor;
  }

  function deriveMarketCreatorFeeAmount(uint256 _amount) public view returns (uint256) {
    if (feeDivisor == 0) {
      return 0;
    }
    return _amount / feeDivisor;
  }

  function withdrawInEmergency() public onlyInBadTimes onlyOwner returns (bool) {
    if (address(this).balance > 0) {
      msg.sender.transfer(address(this).balance);
    }
    return true;
  }

  function getTypeName() public view returns (bytes32) {
    return "Market";
  }

  function isResolved() public view returns (bool) {
    return getResolutionTime() != 0;
  }

  function getEndTime() public view returns (uint256) {
    return endTime;
  }

  function getMarketCreatorMailbox() public view returns (IMailbox) {
    return marketCreatorMailbox;
  }

  function isInvalid() public view returns (bool) {
    require(isResolved());
    return invalid;
  }

  function getOracle() public view returns (address) {
    return address(oracle);
  }

  function getPayoutNumerator(uint256 _outcome) public view returns (uint256) {
    require(isResolved());
    return payoutNumerators[_outcome];
  }

  function getUniverse() public view returns (IUniverse) {
    return universe;
  }

  function getResolutionTime() public view returns (uint256) {
    return resolutionTime;
  }

  function getNumberOfOutcomes() public view returns (uint256) {
    return numOutcomes;
  }

  function getNumTicks() public view returns (uint256) {
    return numTicks;
  }

  function getDenominationToken() public view returns (ERC20) {
    return denominationToken;
  }

  function getShareToken(uint256 _outcome) public view returns (IShareToken) {
    return shareTokens[_outcome];
  }

  function isContainerForShareToken(IShareToken _shadyShareToken) public view returns (bool) {
    return getShareToken(_shadyShareToken.getOutcome()) == _shadyShareToken;
  }

  function onTransferOwnership(address _owner, address _newOwner) internal returns (bool) {
    controller.getAugurLite().logMarketTransferred(getUniverse(), _owner, _newOwner);
    return true;
  }

  function verifyResolutionInformation(uint256[] _payoutNumerators, bool _invalid) public view returns (bool) {
    uint256 _sum = 0;
    uint256 _previousValue = _payoutNumerators[0];
    require(_payoutNumerators.length == numOutcomes);
    for (uint256 i = 0; i < _payoutNumerators.length; i++) {
      uint256 _value = _payoutNumerators[i];
      _sum = _sum.add(_value);
      require(!_invalid || _value == _previousValue);
      _previousValue = _value;
    }
    if (_invalid) {
      require(_previousValue == numTicks / numOutcomes);
    } else {
      require(_sum == numTicks);
    }
    return true;
  }

  function assertBalances() public view returns (bool) {
    // Escrowed funds for open orders
    uint256 _expectedBalance = 0;
    // Market Open Interest. If we're resolved we need actually calculate the value
    if (isResolved()) {
      for (uint256 i = 0; i < numOutcomes; i++) {
        _expectedBalance = _expectedBalance.add(shareTokens[i].totalSupply().mul(getPayoutNumerator(i)));
      }
    } else {
      _expectedBalance = _expectedBalance.add(shareTokens[0].totalSupply().mul(numTicks));
    }

    assert(denominationToken.balanceOf(this) >= _expectedBalance);
    return true;
  }
}
