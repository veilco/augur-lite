pragma solidity 0.4.25;

import 'ITime.sol';
import 'libraries/Ownable.sol';
import 'Controller.sol';


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
        controller.getVeilAugur().logTimestampSet(timestamp);
        return true;
    }

    function setTimestamp(uint256 _timestamp) external onlyOwner returns (bool) {
        timestamp = _timestamp;
        controller.getVeilAugur().logTimestampSet(timestamp);
        return true;
    }

    function getTypeName() public view returns (bytes32) {
        return "TimeControlled";
    }

    function onTransferOwnership(address, address) internal returns (bool) {
        return true;
    }
}
