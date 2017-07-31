var FedCoupLedger = artifacts.require("./FedCoupLedger.sol");
var FedCoup = artifacts.require("./FedCoup.sol");

module.exports = function(deployer) {
	//deploy fedcoup
//	deployer.deploy(FedCoupLedger);
	//deploy fedcoup
//	deployer.deploy(FedCoup);

  	// Deploy FedCoupLedger, then deploy FedCoup, passing in FedCoupLedger's newly deployed address
	deployer.deploy(FedCoupLedger).then(function() {
		return deployer.deploy(FedCoup, FedCoupLedger.address);
	});

};
