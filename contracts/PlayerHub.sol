pragma solidity ^0.4.19;

import "./Pausable.sol";

contract PlayerHub is Pausable {

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

  modifier fromGame() {
    require(msg.sender == address(game));
    _;
  }

  function PlayerHub(bool isPaused)
    Pausable(isPaused)
    public
  {}

  function setGame(address gameAddress)
    fromOwner
    public
  {
    game = gameAddress;
  }

  function deposit()
    whenNotPaused
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
    whenNotPaused
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
    whenNotPaused
    fromGame
    public
    returns(bool success)
  {
    PlayerBalance storage playerBalance = deposits[player];
    playerBalance.balance += creditBalanceAmount;
    return true;
  }

  function deductBalance(address player, uint deductBalanceAmount)
    whenNotPaused
    fromGame
    public
    returns(bool success)
  {
    PlayerBalance storage playerBalance = deposits[player];
    playerBalance.balance -= deductBalanceAmount;
    return true;
  }

  function creditAvailableBalance(address player, uint creditBalanceAmount)
    whenNotPaused
    fromGame
    public
    returns(bool success)
  {
    PlayerBalance storage playerBalance = deposits[player];
    playerBalance.availableBalance += creditBalanceAmount;
    return true;
  }

  function deductAvailableBalance(address player, uint deductBalanceAmount)
    whenNotPaused
    fromGame
    public
    returns(bool success)
  {
    PlayerBalance storage playerBalance = deposits[player];
    require(playerBalance.availableBalance >= deductBalanceAmount);
    playerBalance.availableBalance -= deductBalanceAmount;
    return true;
  }
}