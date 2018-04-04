pragma solidity ^0.4.19;

import "./Stoppable.sol";

contract RockPaperScissors is Stoppable {

  uint constant public EXPIRATION_LIMIT = 10 minutes / 15;

  enum Player { PlayerOne, PlayerTwo }
  enum Move { Rock, Paper, Scissors }

  struct Game {
    address player1;
    bytes32 player1MoveHash;
    address player2;
    bytes32 player2MoveHash;
    Move player1Move;
    Move player2Move;
    uint stake;
    uint expiresAtBlock;
  }

  mapping (bytes32 => Game) private games;

  event LogNewGame(
    address indexed player1,
    address indexed player2,
    uint stake,
    uint expiresAtBlock,
    bytes32 gameKey);

  event LogMove(
    address indexed player,
    address indexed opponent,
    bytes32 moveHash);

  function RockPaperScissors()
    Ownable(msg.sender)
    public
  {}

  // games are created for two specific players up front
  function createGame(address player2, uint stake, uint expiration)
    isActive
    public
    returns(bytes32 gameAddress)
  {
    bytes32 key = getGameKey(msg.sender, player2);
    Game storage game = games[key];

    require(expiration > 0);
    require(player2 != address(0));
    require(game.player1 == address(0));
    require(expiration <= EXPIRATION_LIMIT);
    require(stake % 2 == 0);

    uint expiresAtBlock = block.number + expiration;

    game.player1 = msg.sender;
    game.player2 = player2;
    game.stake = stake;
    game.expiresAtBlock = expiresAtBlock;

    LogNewGame(msg.sender, player2, stake, expiresAtBlock, gameKey);

    return key;
  }

  // only one game between the two same players at any given time
  function getGameKey(address player1, address player2)
    isActive
    view
    public
    returns(bytes32 gameKey)
  {
    return keccak256(this, player1, player2);
  }

  function createMoveHash(bytes32 password)
    isActive
    view
    public
    returns(bytes32 moveHash)
  {
    return keccak256(this, msg.sender, password);
  }

  function playMove(Player player, address opponent, bytes32 moveHash)
    isActive
    public
    payable
    returns(bool success)
  {
    require(opponent != address(0));
    // todo: is this needed?
    require(player == Player.PlayerOne || player == Player.PlayerTwo);

    address player1;
    address player2;
    if (player == Player.PlayerOne) {
      player1 = msg.sender;
      player2 = opponent;
    } else {
      player1 = opponent;
      player2 = msg.sender;
    }

    bytes32 key = getGameKey(player1, player2);
    Game storage game = games[key];

    require(game.player1 != address(0));
    require(msg.value % 2 == 0);
    require(msg.value == (game.stake / 2));

    if (player == Player.PlayerOne) {
      game.player1MoveHash = moveHash;
    } else {
      game.player2MoveHash = moveHash;
    }

    LogMove(msg.sender, opponent, moveHash);
    return true;
  }
}