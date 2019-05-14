pragma solidity 0.4.26;

import 'Controlled.sol';
import 'libraries/ITyped.sol';
import 'libraries/token/VariableSupplyToken.sol';
import 'libraries/DelegationTarget.sol';


contract TestNetDenominationToken is DelegationTarget, ITyped, VariableSupplyToken {

  string constant public name = "TestNetDenominationToken";
  string constant public symbol = "TNDT";
  uint8 constant public decimals = 18;

  function depositEther() public payable returns(bool) {
    mint(msg.sender, msg.value);
    assert(address(this).balance >= totalSupply());
    return true;
  }

  function withdrawEther(uint256 _amount) public returns(bool) {
    withdrawEtherInternal(msg.sender, msg.sender, _amount);
    return true;
  }

  function withdrawEtherInternal(address _from, address _to, uint256 _amount) private returns(bool) {
    require(_amount > 0 && _amount <= balances[_from], "Invalid amount to withdraw");
    burn(_from, _amount);
    _to.transfer(_amount);
    assert(address(this).balance >= totalSupply());
    return true;
  }

  function getTypeName() public view returns (bytes32) {
    return "TestNetDenominationToken";
  }

  function onMint(address, uint256) internal returns (bool) {
    return true;
  }

  function onBurn(address, uint256) internal returns (bool) {
    return true;
  }

  function onTokenTransfer(address, address, uint256) internal returns (bool) {
    return true;
  }
}
