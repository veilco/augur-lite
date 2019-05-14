pragma solidity 0.4.26;

import 'IMailbox.sol';
import 'IMarket.sol';
import 'IController.sol';
import 'libraries/Delegator.sol';


contract MailboxFactory {
  function createMailbox(IController _controller, address _owner, IMarket _market) public returns (IMailbox) {
    Delegator _delegator = new Delegator(_controller, "Mailbox");
    IMailbox _mailbox = IMailbox(_delegator);
    _mailbox.initialize(_owner, _market);
    return _mailbox;
  }
}
