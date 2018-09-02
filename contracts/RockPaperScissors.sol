pragma solidity ^0.4.19;

import "./Pausable.sol";
import "./PlayerHub.sol";

contract RockPaperScissors is Pausable {

  uint constant public EXPIRATION_LIMIT = 10 minutes / 15;

  enum Move { None, Rock, Paper, Scissors }

  struct Game {
    address     player1;
    bytes32     player1MoveHash;
    Move        player1Move;

    address     player2;
    bytes32     player2MoveHash;
    Move        player2Move;

    uint        stake;
    uint        expiresAtBlock;
  }

  mapping (bytes32 => Game) public games;
  PlayerHub public playerHub;

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

  event LogResolvedGame(
    address indexed player1,
    address indexed player2,
    bytes32 gameKey);

  function RockPaperScissors(address playerHubAddr, bool isPaused)
    Pausable(isPaused)
    public
  {
    playerHub = PlayerHub(playerHubAddr);
  }

  // games are created for two specific players up front
  function createGame(address player2, uint stake, uint expiration)
    whenNotPaused
    public
    returns(bytes32 gameKey)
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
    whenNotPaused
    view
    public
    returns(bytes32 gameKey)
  {
    return keccak256(this, player1, player2);
  }

  function createMoveHash(Move move, bytes32 hashSecret)
    whenNotPaused
    view
    public
    returns(bytes32 moveHash)
  {
    return keccak256(this, msg.sender, move, hashSecret);
  }

  function resolveGame(bytes32 gameKey)
    whenNotPaused
    private
    returns(bool success)
  {
    Game storage game = games[gameKey];

    uint player1Move = uint(game.player1Move);
    uint player2Move = uint(game.player2Move);
    require(player1Move != 0);
    require(player2Move != 0);

    uint halfStake = (game.stake / 2);
    if (player1Move == player2Move) {
      // tie - balance doesn't change, return pledged balance
      playerHub.creditAvailableBalance(game.player1, halfStake);
      playerHub.creditAvailableBalance(game.player2, halfStake);
    } else if ((3 + player1Move - player2Move) % 3 == 1) {
      // player 1 win
      // don't refund player 2 available balance and deduct balance by halfstake
      playerHub.deductBalance(game.player2, halfStake);
      // refund player 1 available balance and credit with halfstake
      playerHub.creditBalance(game.player1, halfStake);
      playerHub.creditAvailableBalance(game.player1, game.stake);
    } else {
      // player 2 win
      playerHub.deductBalance(game.player1, halfStake);
      playerHub.creditBalance(game.player2, halfStake);
      playerHub.creditAvailableBalance(game.player2, game.stake);
    }

    LogResolvedGame(game.player1, game.player2, gameKey);

    return true;
  }

  function playMove(bytes32 gameKey, bytes32 moveHash)
    whenNotPaused
    public
    returns(bool success)
  {
    Game storage game = games[gameKey];

    require(game.expiresAtBlock < block.number);
    // verify that game is initialised/exists
    require(msg.sender == game.player1 || msg.sender == game.player2);

    // both players need to have not revealed their move to play a move
    require(game.player1MoveHash == 0);
    require(game.player2MoveHash == 0);

    require(playerHub.deductAvailableBalance(msg.sender, (game.stake / 2)));

    if (msg.sender == game.player1) {
      game.player1MoveHash = moveHash;
    } else {
      game.player2MoveHash = moveHash;
    }

    LogPlayedMove(msg.sender, gameKey, moveHash);

    return true;
  }

  function revealMove(bytes32 gameKey, Move move, bytes32 hashSecret)
    whenNotPaused
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

    if (game.player1Move != Move.None && game.player2Move != Move.None) {
      resolveGame(gameKey);
    }

    return true;
  }
}