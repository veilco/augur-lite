pragma solidity 0.4.25;

import 'Controlled.sol';


contract DelegationTarget is Controlled {
  bytes32 public controllerLookupName;
}
