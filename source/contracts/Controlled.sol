pragma solidity ^0.4.13;

import 'IControlled.sol';
import 'IController.sol';


contract Controlled is IControlled {
    IController internal controller;

    modifier onlyWhitelistedCallers {
        require(controller.assertIsWhitelisted(msg.sender));
        _;
    }

    modifier onlyControllerCaller {
        require(IController(msg.sender) == controller);
        _;
    }

    modifier onlyInGoodTimes {
        require(controller.stopInEmergency());
        _;
    }

    modifier onlyInBadTimes {
        require(controller.onlyInEmergency());
        _;
    }

    function Controlled() {
        controller = IController(msg.sender);
    }

    function setController(IController _controller) public onlyControllerCaller returns(bool) {
        controller = _controller;
        return true;
    }

    function suicideFunds(address _target) public onlyControllerCaller returns(bool) {
        // Transfer REP tokens to target
        ERC20Basic repToken = ERC20Basic(controller.lookup("Reputation"));
        uint256 balance = repToken.balanceOf(this);
        repToken.transfer(_target, balance);

        // Transfer Eth to target and terminate contract
        selfdestruct(_target);
        return true;
    }
}
