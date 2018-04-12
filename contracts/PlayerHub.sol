pragma solidity ^0.4.19;

import "./Stoppable.sol";

contract PlayerHub is Stoppable {

  mapping (address => uint) public deposits;

  event LogDeposit(
    address indexed player,
    uint value
  );

  event LogWithdraw(
    address indexed player,
    uint value
  );

  function PlayerHub()
    Ownable(msg.sender)
    public
  {}

  function deposit()
    isActive
    public
    payable
    returns(bool success)
  {
    deposits[msg.sender] += msg.value;
    LogDeposit(msg.sender, msg.value);

    return true;
  }

  function withdraw()
    isActive
    public
    returns(bool success)
  {
    uint value = deposits[msg.sender];
    require(value > 0);
    deposits[msg.sender] = 0;
    LogWithdraw(msg.sender, value);
    msg.sender.transfer(value);

    return true;
  }
}