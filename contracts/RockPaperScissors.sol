pragma solidity ^0.4.19;

import "./Stoppable.sol";

contract RockPaperScissors is Stoppable {

  uint constant public EXPIRATION_LIMIT = 10 minutes / 15;

  enum Move { Rock, Paper, Scissors }

  struct Game {
    address     player1;
    bytes32     player1MoveHash;
    Move        player1Move;
    uint        player1Deposit;

    address     player2;
    bytes32     player2MoveHash;
    Move        player2Move;
    uint        player2Deposit;

    uint        stake;
    uint        expiresAtBlock;
  }

  mapping (bytes32 => Game) private games;

  event LogNewGame(
    address indexed player1,
    address indexed player2,
    uint stake,
    uint expiresAtBlock,
    bytes32 gameKey);

  event LogPlayedMove(
    address indexed player,
    bytes32 gameKey,
    bytes32 moveHash);

  event LogRevealedMove(
    address indexed player,
    bytes32 gameKey,
    Move move,
    bytes32 hashSecret);

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
    bytes32 key = createGameKey(msg.sender, player2);
    Game storage game = games[key];

    require(expiration > 0);
    require(player2 != address(0));
    // check game doesn't already exist
    require(game.player1 == address(0));
    require(expiration <= EXPIRATION_LIMIT);
    require(stake % 2 == 0);

    uint expiresAtBlock = block.number + expiration;

    game.player1 = msg.sender;
    game.player2 = player2;
    game.stake = stake;
    game.expiresAtBlock = expiresAtBlock;

    LogNewGame(msg.sender, player2, stake, expiresAtBlock, key);

    return key;
  }

  // only one game between the two same players at any given time
  function createGameKey(address player1, address player2)
    isActive
    view
    public
    returns(bytes32 gameKey)
  {
    return keccak256(this, player1, player2);
  }

  function createMoveHash(Move move, bytes32 hashSecret)
    isActive
    view
    public
    returns(bytes32 moveHash)
  {
    return keccak256(this, msg.sender, move, hashSecret);
  }

  function playMove(bytes32 gameKey, bytes32 moveHash)
    isActive
    public
    payable
    returns(bool success)
  {
    Game storage game = games[gameKey];

    require(game.expiresAtBlock < block.number);
    // verify that game is initialised/exists
    require(msg.sender == game.player1 || msg.sender == game.player2);
    require(msg.value % 2 == 0);
    require(msg.value == (game.stake / 2));

    // both players need to have not revealed their move to play a move
    require(game.player1MoveHash == 0);
    require(game.player2MoveHash == 0);

    if (msg.sender == game.player1) {
      game.player1MoveHash = moveHash;
      game.player1Deposit = msg.value;
    } else {
      game.player2MoveHash = moveHash;
      game.player2Deposit = msg.value;
    }

    LogPlayedMove(msg.sender, gameKey, moveHash);

    return true;
  }

  function revealMove(bytes32 gameKey, Move move, bytes32 hashSecret)
    isActive
    public
    returns(bool success)
  {
    Game storage game = games[gameKey];

    require(game.expiresAtBlock < block.number);
    // verify that game is initialised/exists
    require(msg.sender == game.player1 || msg.sender == game.player2);

    require(game.expiresAtBlock < block.number);
    // both players need to have placed their moves before revealing
    require(game.player1MoveHash != 0);
    require(game.player2MoveHash != 0);

    bytes32 moveHash = createMoveHash(move, hashSecret);
    if (msg.sender == game.player1) {
      require(moveHash == game.player1MoveHash);
      game.player1Move = move;
    } else if (msg.sender == game.player2) {
      require(moveHash == game.player2MoveHash);
      game.player2Move = move;
    }

    LogRevealedMove(msg.sender, gameKey, move, hashSecret);

    return true;
  }
}