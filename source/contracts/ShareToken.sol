pragma solidity 0.4.26;

import 'IMarket.sol';
import 'IShareToken.sol';
import 'libraries/DelegationTarget.sol';
import 'libraries/token/VariableSupplyToken.sol';
import 'libraries/ITyped.sol';
import 'libraries/Initializable.sol';


contract ShareToken is DelegationTarget, ITyped, Initializable, VariableSupplyToken, IShareToken {

  string constant public name = "Shares";
  uint8 constant public decimals = 0;
  string constant public symbol = "SHARE";

  IMarket private market;
  uint256 private outcome;

  function initialize(IMarket _market, uint256 _outcome) external beforeInitialized returns(bool) {
    endInitialization();
    market = _market;
    outcome = _outcome;
    return true;
  }

  function createShares(address _owner, uint256 _fxpValue) external onlyWhitelistedCallers returns(bool) {
    mint(_owner, _fxpValue);
    return true;
  }

  function destroyShares(address _owner, uint256 _fxpValue) external onlyWhitelistedCallers returns(bool) {
    burn(_owner, _fxpValue);
    return true;
  }

  function getTypeName() public view returns(bytes32) {
    return "ShareToken";
  }

  function getMarket() external view returns(IMarket) {
    return market;
  }

  function getOutcome() external view returns(uint256) {
    return outcome;
  }

  function onTokenTransfer(address _from, address _to, uint256 _value) internal returns (bool) {
    controller.getAugurLite().logShareTokensTransferred(market.getUniverse(), _from, _to, _value);
    return true;
  }

  function onMint(address _target, uint256 _amount) internal returns (bool) {
    controller.getAugurLite().logShareTokenMinted(market.getUniverse(), _target, _amount);
    return true;
  }

  function onBurn(address _target, uint256 _amount) internal returns (bool) {
    controller.getAugurLite().logShareTokenBurned(market.getUniverse(), _target, _amount);
    return true;
  }
}
