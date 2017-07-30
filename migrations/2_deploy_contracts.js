var FedCoup = artifacts.require("./FedCoup.sol");

module.exports = function(deployer) {
  //deploy fedcoup
  deployer.deploy(FedCoup);
};
