pragma solidity 0.4.26;

/**
 * The Controller is used to manage whitelisting of contracts and and halt the normal use of Augur’s contracts (e.g., if there is a vulnerability found in Augur).  There is only one instance of the Controller, and it gets uploaded to the blockchain before all of the other contracts.  The `owner` attribute of the Controller is set to the address that called the constructor of the Controller.  The Augur team can then call functions from this address to interact with the Controller.
 */

import 'IAugurLite.sol';
import 'IController.sol';
import 'IControlled.sol';
import 'libraries/token/ERC20Basic.sol';
import 'ITime.sol';


contract Controller is IController {
  struct ContractDetails {
    bytes32 name;
    address contractAddress;
    bytes20 commitHash;
    bytes32 bytecodeHash;
  }

  address public owner;
  mapping(address => bool) public whitelist;
  mapping(bytes32 => ContractDetails) public registry;
  bool public stopped = false;

  constructor() public {
    owner = msg.sender;
    whitelist[msg.sender] = true;
  }

  modifier onlyOwnerCaller {
    require(msg.sender == owner, "Sender is not the owner");
    _;
  }

  modifier onlyInBadTimes {
    require(stopped, "Emergency stop is not active");
    _;
  }

  modifier onlyInGoodTimes {
    require(!stopped, "Emergency stop is active");
    _;
  }

  /*
   * Contract Administration
   */

  function addToWhitelist(address _target) public onlyOwnerCaller returns (bool) {
    whitelist[_target] = true;
    return true;
  }

  function removeFromWhitelist(address _target) public onlyOwnerCaller returns (bool) {
    whitelist[_target] = false;
    return true;
  }

  function assertIsWhitelisted(address _target) public view returns (bool) {
    require(whitelist[_target], "Target is not whitelisted");
    return true;
  }

  function registerContract(bytes32 _key, address _address, bytes20 _commitHash, bytes32 _bytecodeHash) public onlyOwnerCaller returns (bool) {
    require(registry[_key].contractAddress == address(0), "Contract is already registered");
    registry[_key] = ContractDetails(_key, _address, _commitHash, _bytecodeHash);
    return true;
  }

  function getContractDetails(bytes32 _key) public view returns (address, bytes20, bytes32) {
    ContractDetails storage _details = registry[_key];
    return (_details.contractAddress, _details.commitHash, _details.bytecodeHash);
  }

  function lookup(bytes32 _key) public view returns (address) {
    return registry[_key].contractAddress;
  }

  function transferOwnership(address _newOwner) public onlyOwnerCaller returns (bool) {
    owner = _newOwner;
    return true;
  }

  function emergencyStop() public onlyOwnerCaller onlyInGoodTimes returns (bool) {
    getAugurLite().logEscapeHatchChanged(true);
    stopped = true;
    return true;
  }

  function stopInEmergency() public view onlyInGoodTimes returns (bool) {
    return true;
  }

  function onlyInEmergency() public view onlyInBadTimes returns (bool) {
    return true;
  }

  /*
   * Helper functions
   */

  function getAugurLite() public view returns (IAugurLite) {
    return IAugurLite(lookup("AugurLite"));
  }

  function getTimestamp() public view returns (uint256) {
    return ITime(lookup("Time")).getTimestamp();
  }
}
