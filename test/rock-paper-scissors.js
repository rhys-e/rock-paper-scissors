const Promise = require("bluebird");
const { wait, waitUntilBlock } = require("@digix/tempo")(web3);
const getBalance = Promise.promisify(web3.eth.getBalance);
const BigNumber = require("bignumber.js");
const PlayerHub = artifacts.require("./PlayerHub.sol");
const RockPaperScissors = artifacts.require("./RockPaperScissors.sol");

contract("RockPaperScissors", (accounts) => {

  const owner = accounts[0];
  const player1 = accounts[1];
  const player2 = accounts[2];
  const gasPrice = new BigNumber("100000000000");

  let playerHub;
  let rpsGame;
  let expirationLimit;

  before(() => {
    return PlayerHub.new({ from: owner })
      .then(instance => {
        playerHub = instance;
      })
      .then(() => playerHub.rpsGame())
      .then(game => {
        rpsGame = RockPaperScissors.at(game);
      })
      .then(() => rpsGame.EXPIRATION_LIMIT())
      .then(limit => {
        expirationLimit = limit;
        assert(expirationLimit > 0);
      });
  });

  describe("should prevent games with bad parameters from being created", () => {
    it("should reject games with 0 expiration", () => {
      return rpsGame.createGame(player2, 0, 0, { from: player1 })
        .then(assert.fail)
        .catch(err => {
          assert.include(err.message, "revert", "should revert on 0 expiration");
        });
    });

    it("should reject games with a 0 player2 address", () => {
      return rpsGame.createGame(0, 0, 10, { from: player1 })
        .then(assert.fail)
        .catch(err => {
          assert.include(err.message, "revert", "should revert on a 0 player2 address");
        });
    });

    it("should reject games with an expiration greater than the expiration limit", () => {
      return rpsGame.createGame(player2, 0, expirationLimit + 1, { from: player1 })
        .then(assert.fail)
        .catch(err => {
          assert.include(err.message, "revert", "should revert on an expiration greater than the expiration limit");
        });
    });

    it("should reject games with a stake not divisible by 2", () => {
      return rpsGame.createGame(player2, 1, 10, { from: player1 })
        .then(assert.fail)
        .catch(err => {
          assert.include(err.message, "revert", "should reject games with a stake not divisible by 2");
        });
    });
  });

  describe("should prevent moves with bad parameters from being played", () => {

    let gameKey;

    before(() => {
      return rpsGame.createGame(player2, 10, 10, { from: player1 })
        .then(() => Promise.promisify(rpsGame.allEvents().watch, { context: rpsGame.allEvents() })())
        .then(event => {
          gameKey = event.args.gameKey;
        });
    });

    it("should reject move if game has expired", () => {
      const blockNumber = web3.eth.blockNumber;

      return waitUntilBlock(1, blockNumber + 11)
        .then(() => rpsGame.playMove(gameKey, 0x0, { from: player1 }))
        .then(assert.fail)
        .catch(err => {
          assert.include(err.message, "revert", "should revert when block number is beyond game expiry");
        });
    });

    it("should reject move if sender is not one of the game players", () => {
      return rpsGame.playMove(gameKey, 0x0, { from: accounts[0] })
        .then(assert.fail)
        .catch(err => {
          assert.include(err.message, "revert", "should revert when player is not part of game");
        });
    });

    it("should reject move if either player's move has already been revealed", () => {
      return rpsGame.createMoveHash(1, "abc", { from: player1 })
        .then(hash => rpsGame.playMove(gameKey, hash, { from: player1 }))
        .then(() => rpsGame.createMoveHash(2, "xyz", { from: player2 }))
        .then(hash => rpsGame.playMove(gameKey, hash, { from: player2 }))
        .then(() => rpsGame.revealMove(gameKey, 1, "abc"), { from: player1 })
        .then(() => assert.ok())
        .then(() => rpsGame.playMove(gameKey, 0x0, { from: player1 }))
        .then(assert.fail)
        .catch(err => {
          assert.include(err.message, "revert", "should reject a move after reveal has already taken place");
        });
    });

    it("should reject move if not enough available balance", () => {
      return playerHub.deposit({ from: player1, value: 4 })
        .then(() => rpsGame.playMove(gameKey, 0x0, { from: player1 }))
        .then(assert.fail)
        .catch(err => {
          assert.include(err.message, "revert", "should revert when player doesn't have high enough balance");
        });
    });
  });
});
