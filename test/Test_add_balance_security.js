var FedCoup = artifacts.require("./FedCoup.sol");

contract('FedCoup', function(accounts) {
  /* test initial total supply */
  it("should put 0 in the first account", function() {
    return FedCoup.deployed().then(function(instance) {
      return instance.balanceOf.call(accounts[0]);
    }).then(function( _FCCBalance ) {
      assert.equal(_FCCBalance.valueOf(), 0, "0 wasn't in the first account");
    });
  });

});
