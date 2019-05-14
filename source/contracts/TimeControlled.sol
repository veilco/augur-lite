pragma solidity 0.4.26;

import 'ITime.sol';
import 'Controller.sol';
import 'libraries/Ownable.sol';


contract TimeControlled is ITime, Ownable {

  uint256 private timestamp = 1;

  constructor() public {
    timestamp = block.timestamp;
  }

  function getTimestamp() external view returns (uint256) {
    return timestamp;
  }

  function incrementTimestamp(uint256 _amount) external onlyOwner returns (bool) {
    timestamp += _amount;
    controller.getAugurLite().logTimestampSet(timestamp);
    return true;
  }

  function setTimestamp(uint256 _timestamp) external onlyOwner returns (bool) {
    timestamp = _timestamp;
    controller.getAugurLite().logTimestampSet(timestamp);
    return true;
  }

  function getTypeName() public view returns (bytes32) {
    return "TimeControlled";
  }

  function onTransferOwnership(address, address) internal returns (bool) {
    return true;
  }
}
