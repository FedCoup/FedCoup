var FedCoup = artifacts.require("./FedCoup.sol");

contract('FedCoup', function(accounts) {

  var fedCoupInstance = FedCoup.deployed();

  //   /* test token approval */
  // it("should approve 100 tokens to account1 from contract creator", function() {
  //   return fedCoupInstance.then(function(instance) {
  //       return instance.approve(accounts[1], 100000000000000000000);
  //   }).then(function(txHash) {
  //     return fedCoupInstance.then(function(instance){
  //       instance.allowance.call(accounts[0], accounts[1]).then(function(approvedAmt){
  //         // console.log("first:" + approvedAmt);
  //         assert.equal(approvedAmt.valueOf(), 1e+20, "100 tokens approved from account 1 to 0 is not reflected");
  //       })
  //     })
  //   })
  // });
 
});
