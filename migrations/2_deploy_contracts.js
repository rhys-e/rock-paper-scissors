const PlayerHub = artifacts.require("./PlayerHub.sol");

module.exports = function(deployer) {
  deployer.deploy(PlayerHub);
}
