const PlayerHub = artifacts.require("./PlayerHub.sol");
const RockPaperScissors = artifacts.require("./RockPaperScissors.sol");

module.exports = function(deployer) {
  deployer.deploy(RockPaperScissors);
  deployer.deploy(PlayerHub);
}
