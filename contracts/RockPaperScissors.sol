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

  event LogPlayedMove(
    address indexed player,
    address indexed opponent,
    bytes32 moveHash);

  event LogRevealedMove(
    address indexed player,
    address indexed opponent,
    Move move);

  function RockPaperScissors()
    Ownable(msg.sender)
    public
  {}

  modifier isPlayer(Player player) {
    require(player == Player.PlayerOne || player == Player.PlayerTwo);
    _;
  }

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
  function getGameKey(address player1, address player2)
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

  function getPlayers(address unidentifiedPlayer, address opponentPlayer, Player claimedPlayer)
    pure
    private
    returns(address, address)
  {
    address player1;
    address player2;
    if (claimedPlayer == Player.PlayerOne) {
      player1 = unidentifiedPlayer;
      player2 = opponentPlayer;
    } else {
      player1 = opponentPlayer;
      player2 = unidentifiedPlayer;
    }

    return (player1, player2);
  }

  function getGame(address player1, address player2)
    view
    private
    returns(Game storage)
  {
    bytes32 key = getGameKey(player1, player2);
    Game storage game = games[key];

    // verify that game is initialised/exists
    require(game.player1 == player1);
    return game;
  }

  function playMove(Player player, address opponent, bytes32 moveHash)
    isActive
    isPlayer(player)
    public
    payable
    returns(bool success)
  {
    require(opponent != address(0));

    address player1;
    address player2;

    (player1, player2) = getPlayers(msg.sender, opponent, player);
    Game storage game = getGame(player1, player2);

    require(game.expiresAtBlock < block.number);
    require(msg.value % 2 == 0);
    require(msg.value == (game.stake / 2));

    if (player == Player.PlayerOne) {
      game.player1MoveHash = moveHash;
    } else {
      game.player2MoveHash = moveHash;
    }

    LogPlayedMove(msg.sender, opponent, moveHash);

    return true;
  }

  function revealMove(Player player, address opponent, Move move, bytes32 hashSecret)
    isActive
    isPlayer(player)
    public
    returns(bool success)
  {
    require(opponent != address(0));

    address player1;
    address player2;

    (player1, player2) = getPlayers(msg.sender, opponent, player);

    Game storage game = getGame(player1, player2);

    require(game.expiresAtBlock < block.number);
    // both players need to have placed their moves before revealing
    require(game.player1MoveHash != 0);
    require(game.player2MoveHash != 0);

    bytes32 moveHash = createMoveHash(move, hashSecret);
    if (player == Player.PlayerOne) {
      require(moveHash == game.player1MoveHash);
      game.player1Move = move;
    } else {
      require(moveHash == game.player2MoveHash);
      game.player2Move = move;
    }

    LogRevealedMove(msg.sender, opponent, move);

    return true;
  }
}