var FedCoup = artifacts.require("./FedCoup.sol");

contract('FedCoup', function(accounts) {

  var fedCoupInstance = FedCoup.deployed();

  // /* test initial total supply */
  // it("should put 1B in the contract creator", function() {
  //   return fedCoupInstance.then(function(instance) {
  //     return instance.balanceOf.call(accounts[0]);
  //   }).then(function( _FETBalance ) {
  //     assert.equal(_FETBalance.valueOf(), 1e+27, "1B wasn't in the contract creator");
  //   });
  // });

  // /* test total supply */
  // it("should put 1B in the total supply", function() {
  //   return fedCoupInstance.then(function(instance) {
  //     return instance.totalSupply.call();
  //   }).then(function( _totalSupply ) {
  //     assert.equal(_totalSupply.valueOf(), 1e+27, "1B wasn't in the total supply");
  //   });
  // });

  // /* test token transfer */
  // it("should put 100 tokens to another account from contract creator", function() {
  //   return fedCoupInstance.then(function(instance) {
  //       instance.transfer(accounts[1], 100000000000000000000);
  //   }).then(function(txHash) {
  //     fedCoupInstance.then(function(instance){
  //       instance.balanceOf.call(accounts[1]).then(function(balance){
  //         assert.equal(balance.valueOf(), 1e+20, "100 token transfered from account 0 to 1 is not reflected");
  //       });  
  //     });
  //   });
  // });

  // /* test token approval */
  // it("should approve 100 tokens to account1 from contract creator", function() {
  //   return fedCoupInstance.then(function(instance) {
  //       instance.approve(accounts[1], 100000000000000000000);
  //   }).then(function(txHash) {
  //     fedCoupInstance.then(function(instance){
  //       instance.allowance.call(accounts[0], accounts[1]).then(function(approvedAmt){
  //         assert.equal(approvedAmt.valueOf(), 1e+20, "100 tokens approved from account 1 to 0 is not reflected");
  //       });  
  //     });
  //   });
  // });

  /* test token transfer using approval */
  it("should approve and allow to transfer 100 tokens to account1 from contract creator", function() {
    return fedCoupInstance.then(function(instance) {
        instance.approve(accounts[1], 100000000000000000000);
        instance.transferFrom(accounts[0], 100000000000000000000, {from: accounts[1]});
    }).then(function(txHash) {
      fedCoupInstance.then(function(instance) {
        instance.balanceOf.call(accounts[1]).then(function(balance){
          assert.equal(balance.valueOf(), 1e+20, "100 tokens not transfered from account 0 to 1");
        });  
      });
    });
  });

});
