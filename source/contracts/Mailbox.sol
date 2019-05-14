pragma solidity 0.4.26;

import 'IMailbox.sol';
import 'IMarket.sol';
import 'libraries/DelegationTarget.sol';
import 'libraries/Ownable.sol';
import 'libraries/token/ERC20Basic.sol';
import 'libraries/Initializable.sol';


contract Mailbox is DelegationTarget, Ownable, Initializable, IMailbox {
  IMarket private market;

  function initialize(address _owner, IMarket _market) public onlyInGoodTimes beforeInitialized returns (bool) {
    endInitialization();
    owner = _owner;
    market = _market;
    return true;
  }

  function withdrawTokens(ERC20Basic _token) public onlyOwner returns (bool) {
    uint256 _balance = _token.balanceOf(this);
    require(_token.transfer(owner, _balance), "Token transfer failed");
    return true;
  }

  function onTransferOwnership(address _owner, address _newOwner) internal returns (bool) {
    controller.getAugurLite().logMarketMailboxTransferred(market.getUniverse(), market, _owner, _newOwner);
    return true;
  }
}
