pragma solidity 0.4.26;

import 'Controlled.sol';
import 'IMarket.sol';
import 'libraries/ReentrancyGuard.sol';
import 'libraries/MarketValidator.sol';
import 'libraries/token/ERC20.sol';
import 'libraries/math/SafeMathUint256.sol';


/**
 * @title ClaimTradingProceeds
 * @dev This allows users to claim their money from a market by exchanging their shares
 */
contract ClaimTradingProceeds is ReentrancyGuard, MarketValidator {
  using SafeMathUint256 for uint256;

  function claimTradingProceeds(IMarket _market, address _shareHolder) marketIsLegit(_market) onlyInGoodTimes nonReentrant external returns(bool) {
    // NOTE: this requirement does _not_ enforce market finalization. That requirement occurs later on in this function when calling getPayoutNumerator. When this requirement is removed we may want to consider explicitly requiring it here (or modifying this comment and keeping the gas savings)
    require(controller.getTimestamp() > _market.getResolutionTime(), "Resolution time is not in the past");

    ERC20 denominationToken = _market.getDenominationToken();

    for (uint256 _outcome = 0; _outcome < _market.getNumberOfOutcomes(); ++_outcome) {
      IShareToken _shareToken = _market.getShareToken(_outcome);
      uint256 _numberOfShares = _shareToken.balanceOf(_shareHolder);
      uint256 _proceeds;
      uint256 _shareHolderShare;
      uint256 _creatorShare;
      (_proceeds, _shareHolderShare, _creatorShare) = divideUpWinnings(_market, _outcome, _numberOfShares);

      // always destroy shares as it gives a minor gas refund and is good for the network
      if (_numberOfShares > 0) {
        _shareToken.destroyShares(_shareHolder, _numberOfShares);
        logTradingProceedsClaimed(_market, _shareToken, _shareHolder, _numberOfShares, _shareHolderShare);
      }
      if (_shareHolderShare > 0) {
        require(denominationToken.transferFrom(_market, _shareHolder, _shareHolderShare), "Denomination token transfer failed");
      }
      if (_creatorShare > 0) {
        require(denominationToken.transferFrom(_market, _market.getMarketCreatorMailbox(), _creatorShare), "Denomination token transfer failed");
      }
    }

    _market.assertBalances();

    return true;
  }

  function logTradingProceedsClaimed(IMarket _market, address _shareToken, address _sender, uint256 _numShares, uint256 _numPayoutTokens) private returns (bool) {
    controller.getAugurLite().logTradingProceedsClaimed(_market.getUniverse(), _shareToken, _sender, _market, _numShares, _numPayoutTokens, _market.getDenominationToken().balanceOf(_sender).add(_numPayoutTokens));
    return true;
  }

  function divideUpWinnings(IMarket _market, uint256 _outcome, uint256 _numberOfShares) public view returns (uint256 _proceeds, uint256 _shareHolderShare, uint256 _creatorShare) {
    _proceeds = calculateProceeds(_market, _outcome, _numberOfShares);
    _creatorShare = calculateCreatorFee(_market, _proceeds);
    _shareHolderShare = _proceeds.sub(_creatorShare);
    return (_proceeds, _shareHolderShare, _creatorShare);
  }

  function calculateProceeds(IMarket _market, uint256 _outcome, uint256 _numberOfShares) public view returns (uint256) {
    uint256 _payoutNumerator = _market.getPayoutNumerator(_outcome);
    return _numberOfShares.mul(_payoutNumerator);
  }

  function calculateCreatorFee(IMarket _market, uint256 _amount) public view returns (uint256) {
    return _market.deriveMarketCreatorFeeAmount(_amount);
  }
}
