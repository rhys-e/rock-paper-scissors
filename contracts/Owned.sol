pragma solidity ^0.4.19;

contract Owned {
  address private ownerAddress;

  event LogOwnerSet(
    address indexed previousOwner,
    address indexed newOwner);

  function Owned() public {
    ownerAddress = msg.sender;
  }

  modifier fromOwner() {
    require (msg.sender == ownerAddress);
    _;
  }

  function setOwner(address newOwner)
    public
    fromOwner
    returns (bool success)
  {
    require(newOwner != address(0));
    require(newOwner != ownerAddress);

    emit LogOwnerSet(ownerAddress, newOwner);
    ownerAddress = newOwner;

    return true;
  }

  function getOwner()
    view
    public
    returns(address owner)
  {
    return ownerAddress;
  }
}