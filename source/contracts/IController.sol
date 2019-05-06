pragma solidity 0.4.25;

import 'IVeilAugur.sol';


contract IController {
  function assertIsWhitelisted(address _target) public view returns(bool);
  function lookup(bytes32 _key) public view returns(address);
  function stopInEmergency() public view returns(bool);
  function onlyInEmergency() public view returns(bool);
  function getVeilAugur() public view returns (IVeilAugur);
  function getTimestamp() public view returns (uint256);
  function emergencyStop() public returns (bool);
}
