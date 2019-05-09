pragma solidity 0.4.26;

import 'trading/ICompleteSets.sol';
import 'IAugurLite.sol';
import 'Controlled.sol';
import 'libraries/ReentrancyGuard.sol';
import 'libraries/math/SafeMathUint256.sol';
import 'libraries/MarketValidator.sol';
import 'libraries/token/ERC20.sol';
import 'reporting/IMarket.sol';


contract CompleteSets is Controlled, ReentrancyGuard, MarketValidator, ICompleteSets {
  using SafeMathUint256 for uint256;

  /**
   * Buys `_amount` shares of every outcome in the specified market.
  **/

  function publicBuyCompleteSets(IMarket _market, uint256 _amount) external marketIsLegit(_market) onlyInGoodTimes returns (bool) {
    this.buyCompleteSets(msg.sender, _market, _amount);
    controller.getAugurLite().logCompleteSetsPurchased(_market.getUniverse(), _market, msg.sender, _amount);
    _market.assertBalances();
    return true;
  }

  function buyCompleteSets(address _sender, IMarket _market, uint256 _amount) external onlyWhitelistedCallers nonReentrant returns (bool) {
    require(_sender != address(0));

    uint256 _numOutcomes = _market.getNumberOfOutcomes();
    ERC20 _denominationToken = _market.getDenominationToken();
    IAugurLite _augurLite = controller.getAugurLite();

    uint256 _cost = _amount.mul(_market.getNumTicks());
    require(_augurLite.trustedTransfer(_denominationToken, _sender, _market, _cost));
    for (uint256 _outcome = 0; _outcome < _numOutcomes; ++_outcome) {
      _market.getShareToken(_outcome).createShares(_sender, _amount);
    }

    return true;
  }

  function publicSellCompleteSets(IMarket _market, uint256 _amount) external marketIsLegit(_market) onlyInGoodTimes returns (bool) {
    this.sellCompleteSets(msg.sender, _market, _amount);
    controller.getAugurLite().logCompleteSetsSold(_market.getUniverse(), _market, msg.sender, _amount);
    _market.assertBalances();
    return true;
  }

  function sellCompleteSets(address _sender, IMarket _market, uint256 _amount) external onlyWhitelistedCallers nonReentrant returns (bool) {
    require(_sender != address(0));

    uint256 _numOutcomes = _market.getNumberOfOutcomes();
    ERC20 _denominationToken = _market.getDenominationToken();
    uint256 _payout = _amount.mul(_market.getNumTicks());
    uint256 _creatorFee = _market.deriveMarketCreatorFeeAmount(_payout);
    _payout = _payout.sub(_creatorFee);

    // Takes shares away from participant and decreases the amount issued in the market since we're exchanging complete sets
    for (uint256 _outcome = 0; _outcome < _numOutcomes; ++_outcome) {
      _market.getShareToken(_outcome).destroyShares(_sender, _amount);
    }

    if (_creatorFee != 0) {
      require(_denominationToken.transferFrom(_market, _market.getMarketCreatorMailbox(), _creatorFee));
    }
    require(_denominationToken.transferFrom(_market, _sender, _payout));

    return true;
  }
}
