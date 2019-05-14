pragma solidity 0.4.26;

import 'IShareToken.sol';
import 'IUniverse.sol';
import 'IMailbox.sol';
import 'libraries/ITyped.sol';
import 'libraries/IOwnable.sol';
import 'libraries/token/ERC20.sol';


contract IMarket is ITyped, IOwnable {
  enum MarketType {
    YES_NO,
    CATEGORICAL,
    SCALAR
  }

  function initialize(IUniverse _universe, uint256 _endTime, uint256 _feePerEthInAttoeth, ERC20 _denominationToken, address _oracle, address _creator, uint256 _numOutcomes, uint256 _numTicks) public returns (bool _success);
  function getUniverse() public view returns (IUniverse);
  function getNumberOfOutcomes() public view returns (uint256);
  function getNumTicks() public view returns (uint256);
  function getDenominationToken() public view returns (ERC20);
  function getShareToken(uint256 _outcome)  public view returns (IShareToken);
  function getMarketCreatorSettlementFeeDivisor() public view returns (uint256);
  function getEndTime() public view returns (uint256);
  function getMarketCreatorMailbox() public view returns (IMailbox);
  function getPayoutNumerator(uint256 _outcome) public view returns (uint256);
  function getResolutionTime() public view returns (uint256);
  function getOracle() public view returns (address);
  function deriveMarketCreatorFeeAmount(uint256 _amount) public view returns (uint256);
  function isContainerForShareToken(IShareToken _shadyTarget) public view returns (bool);
  function isInvalid() public view returns (bool);
  function isResolved() public view returns (bool);
  function assertBalances() public view returns (bool);
}
