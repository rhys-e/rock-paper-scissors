pragma solidity ^0.4.19;

import "./Stoppable.sol";

contract PlayerHub is Stoppable {

  struct PlayerBalance {
    uint balance;
    uint availableBalance;
  }

  mapping (address => PlayerBalance) public deposits;
  address public game;

  event LogDeposit(
    address indexed player,
    uint value
  );

  event LogWithdraw(
    address indexed player,
    uint withdrawBalance,
    uint remainingBalance
  );

  modifier isGame() {
    require(msg.sender == address(game));
    _;
  }

  function PlayerHub(address gameAddress)
    Ownable(msg.sender)
    public
  {
    game = gameAddress;
  }

  function deposit()
    isActive
    public
    payable
    returns(bool success)
  {
    PlayerBalance storage playerBalance = deposits[msg.sender];
    playerBalance.balance += msg.value;
    playerBalance.availableBalance += msg.value;
    LogDeposit(msg.sender, msg.value);

    return true;
  }

  function withdraw()
    isActive
    public
    returns(bool success)
  {
    PlayerBalance storage playerBalance = deposits[msg.sender];
    uint availableBalance = playerBalance.availableBalance;
    require(availableBalance > 0);
    playerBalance.balance -= availableBalance;
    playerBalance.availableBalance = 0;

    LogWithdraw(msg.sender, availableBalance, playerBalance.balance);
    msg.sender.transfer(availableBalance);

    return true;
  }

  function creditBalance(address player, uint creditBalanceAmount)
    isActive
    isGame
    public
    returns(bool success)
  {
    PlayerBalance storage playerBalance = deposits[player];
    playerBalance.balance += creditBalanceAmount;
    return true;
  }

  function deductBalance(address player, uint deductBalanceAmount)
    isActive
    isGame
    public
    returns(bool success)
  {
    PlayerBalance storage playerBalance = deposits[player];
    playerBalance.balance -= deductBalanceAmount;
    return true;
  }

  function creditAvailableBalance(address player, uint creditBalanceAmount)
    isActive
    isGame
    public
    returns(bool success)
  {
    PlayerBalance storage playerBalance = deposits[player];
    playerBalance.availableBalance += creditBalanceAmount;
    return true;
  }

  function deductAvailableBalance(address player, uint deductBalanceAmount)
    isActive
    isGame
    public
    returns(bool success)
  {
    PlayerBalance storage playerBalance = deposits[player];
    require(playerBalance.availableBalance >= deductBalanceAmount);
    playerBalance.availableBalance -= deductBalanceAmount;
    return true;
  }
}