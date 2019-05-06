pragma solidity 0.4.25;

import 'IController.sol';
import 'libraries/token/ERC20Basic.sol';


contract IControlled {
  function getController() public view returns (IController);
  function setController(IController _controller) public returns(bool);
}
