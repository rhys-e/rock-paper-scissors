const PlayerHub = artifacts.require("./PlayerHub.sol");
const RockPaperScissors = artifacts.require("./RockPaperScissors.sol");

module.exports = function(deployer) {
  deployer.deploy(PlayerHub, false).then(() => {
    return deployer.deploy(RockPaperScissors, PlayerHub.address, false);
  });
}
