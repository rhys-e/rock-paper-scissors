const Promise = require("bluebird");
const getBalance = Promise.promisify(web3.eth.getBalance);
const BigNumber = require("bignumber.js");
const PlayerHub = artifacts.require("./PlayerHub.sol");

contract("PlayerHub", (accounts) => {

  const owner = accounts[0];
  const player1 = accounts[1];
  const player2 = accounts[2];
  const gasPrice = new BigNumber("100000000000");

  let playerHub;
  let rpsGame;

  before(() => {
    return PlayerHub.new({ from: owner })
      .then(instance => {
        playerHub = instance;
      })
      .then(() => playerHub.rpsGame())
      .then(game => {
        rpsGame = game;
      });
  });

  describe("should allow players to deposit and withdraw balances", () => {
    it("should allow player1 to deposit a balance", () => {
      const oneEth = web3.toWei(1, "ether");
      let initBalance;
      let gasUsed;

      return getBalance(player1)
        .then(_balanace => {
          initBalance = _balanace;
        })
        .then(() => playerHub.deposit({ from: player1, value: oneEth }))
        .then(tx => {
          gasUsed = new BigNumber(tx.receipt.gasUsed).times(gasPrice);
        })
        .then(() => getBalance(player1))
        .then(balance => {
          assert(balance.eq(initBalance.minus(gasUsed).minus(oneEth)));
        })
        .then(() => playerHub.deposits(player1))
        .then(deposit => {
          assert(deposit[0].eq(oneEth));
          assert(deposit[1].eq(oneEth));
        });
    });

    it("should allow player1 to withdraw their balance", () => {
      const oneEth = web3.toWei(1, "ether");
      let initBalance;
      let gasUsed;

      return getBalance(player1)
        .then(_balanace => {
          initBalance = _balanace;
        })
        .then(() => playerHub.deposit({ from: player1, value: oneEth }))
        .then(tx => {
          gasUsed = new BigNumber(tx.receipt.gasUsed).times(gasPrice);
        })
        .then(() => playerHub.withdraw({ from: player1 }))
        .then(tx => {
          gasUsed = gasUsed.plus(new BigNumber(tx.receipt.gasUsed).times(gasPrice));
        })
        .then(() => getBalance(player1))
        .then(balance => {
          assert(balance.eq(initBalance.minus(gasUsed).add(oneEth)));
        })
        .then(() => playerHub.deposits(player1))
        .then(deposit => {
          assert(deposit[0].eq(0));
          assert(deposit[1].eq(0));
        });
    })
  });
});