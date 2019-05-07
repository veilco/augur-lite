pragma solidity 0.4.26;

import 'Controlled.sol';
import 'libraries/ITyped.sol';
import 'libraries/token/VariableSupplyToken.sol';
import 'libraries/DelegationTarget.sol';


/**
 * @title TestNetDenominationToken
 */
contract TestNetDenominationToken is DelegationTarget, ITyped, VariableSupplyToken {

  string constant public name = "TestNetDenominationToken";
  string constant public symbol = "TNDT";
  uint8 constant public decimals = 18;

  function depositEther() external payable onlyInGoodTimes returns(bool) {
    mint(msg.sender, msg.value);
    assert(balanceOf(this) >= totalSupply());
    return true;
  }

  function depositEtherFor(address _to) external payable onlyInGoodTimes returns(bool) {
    mint(_to, msg.value);
    assert(balanceOf(this) >= totalSupply());
    return true;
  }

  function withdrawEther(uint256 _amount) external returns(bool) {
    withdrawEtherInternal(msg.sender, msg.sender, _amount);
    return true;
  }

  function withdrawEtherTo(address _to, uint256 _amount) external returns(bool) {
    withdrawEtherInternal(msg.sender, _to, _amount);
    return true;
  }

  function withdrawEtherInternal(address _from, address _to, uint256 _amount) private returns(bool) {
    require(_amount > 0 && _amount <= balances[_from]);
    burn(_from, _amount);
    _to.transfer(_amount);
    assert(balanceOf(this) >= totalSupply());
    return true;
  }

  function withdrawEtherToIfPossible(address _to, uint256 _amount) external returns (bool) {
    require(_amount > 0 && _amount <= balances[msg.sender]);
    if (_to.send(_amount)) {
      burn(msg.sender, _amount);
    } else {
      internalTransfer(msg.sender, _to, _amount);
    }
    assert(balanceOf(this) >= totalSupply());
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
