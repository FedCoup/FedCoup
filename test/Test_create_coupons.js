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

  /* test B coupons initialization */
  it("B coupons should print 0 for first time", function() {
    return FedCoup.deployed().then(function(instance) {
      return instance.getBcouponBalances(accounts[0]);
    }).then(function( Bcoupons ) {
      assert.equal(Bcoupons.valueOf(), 0, "0 wasn't in the B coupons for first time");
    });
  });

    /* test S coupons initialization */
  it("S coupons should print 0 for first time", function() {
    return FedCoup.deployed().then(function(instance) {
      return instance.getScouponBalances(accounts[0]);
    }).then(function( Scoupons ) {
      assert.equal(Scoupons.valueOf(), 0, "0 wasn't in the S coupons for first time");
    });
  });

  /* test residual B coupons initialization */
  it("residual B coupons should print 0 for first time", function() {
    return FedCoup.deployed().then(function(instance) {
      return instance.getBalanceOfResidualBcoupons.call();
    }).then(function( residualBcoupons ) {
      assert.equal(residualBcoupons.valueOf(), 0, "0 wasn't in the residual B coupons for first time");
    });
  });


  /* test transfer B coupons first time */
  it("transfer B coupons if 0 B balance should remain 0 B balance", function() {
    return FedCoup.deployed().then(function(instance) {
      return instance.transferBcoupons.call(accounts[1], 10);
    }).then(function( returnValue ) {
      assert(false, "Throw expected when transfer B coupons when 0 B balance");
    }).catch(function(error) {
      if(error.toString().indexOf("invalid opcode") != -1) {
        assert(true, "Throw expected when transfer B coupons when 0 B balance");
        //accounts[0] B balance should be 0
        FedCoup.deployed().then(function(instance) {
          return instance.getBcouponBalances.call(accounts[0]);
        }).then(function( Bbalance ) {
          assert.equal(Bbalance.valueOf(), 0, "account[0] - 0 wasn't in the B coupons after with initial 0 B balance");  
        });
        //accounts[1] B balance should be 0
        FedCoup.deployed().then(function(instance) {
          return instance.getBcouponBalances.call(accounts[1]);
        }).then(function( Bbalance ) {
          assert.equal(Bbalance.valueOf(), 0, "account[1] - 0 wasn't in the B coupons after with initial 0 B balance");  
        });
      } else {
        // if the error is something else (e.g., the assert from previous promise), then we fail the test
        assert(false, error.toString());
      }
    });
  });

  /* test accept B coupons for initial condition */
  it("accept 1B coupons should throw exception if 0 B balance in beneficiary account", function() {
    return FedCoup.deployed().then(function(instance) {
      return instance.accept_B_coupons.call(accounts[1], 1);
    }).then(function( returnValue ) {
      assert(false, "Throw expected when accept B coupons when 0 B balance in beneficiary account");
    }).catch(function( error ) {
      if(error.toString().indexOf("invalid opcode") != -1) {
        assert(true, "Throw expected when accept B coupons when 0 B balance in beneficiary account");
        //accounts[0] B balance should be 0
        FedCoup.deployed().then(function(instance) {
          return instance.getBcouponBalances.call(accounts[0]);
        }).then(function( Bbalance ) {
          assert.equal(Bbalance.valueOf(), 0, "account[0] - 0 wasn't in the B coupons after with initial 0 B balance");  
        });
        //accounts[0] S balance should be 0
        FedCoup.deployed().then(function(instance) {
          return instance.getScouponBalances.call(accounts[0]);
        }).then(function( Sbalance ) {
          assert.equal(Sbalance.valueOf(), 0, "account[0] - 0 wasn't in the S coupons after with initial 0 S balance");  
        });    
        //accounts[0] FCC balance should be 0
        FedCoup.deployed().then(function(instance) {
          return instance.balanceOf.call(accounts[0]);
        }).then(function( FCCbalance ) {
          assert.equal(FCCbalance.valueOf(), 0, "account[0] - 0 wasn't in the account after with initial 0 FCC balance");  
        });            
        //accounts[1] B balance should be 0
        FedCoup.deployed().then(function(instance) {
          return instance.balanceOf_B_coupons.call(accounts[1]);
        }).then(function( Bbalance ) {
          assert.equal(Bbalance.valueOf(), 0, "account[1] - 0 wasn't in the B coupons after with initial 0 B balance");  
        });
      } else {
        // if the error is something else (e.g., the assert from previous promise), then we fail the test
        assert(false, error.toString());
      }
    });
  });  

  /* test residual B coupons initialization */
  // it("create coupons should print", function() {
  //   return FedCoup.deployed().then(function(instance) {
  //     return instance.getBalanceOfResidualBcoupons.call();
  //   }).then(function( residualBcoupons ) {
  //     assert.equal(residualBcoupons.valueOf(), 0, "0 wasn't in the residual B coupons for first time");
  //   });
  // });


  /* test transfer B coupons first time */
  /*
  it("transfer B coupons if 0 B balance should remain 0 B balance", function() {
    return FedCoup.deployed().then(function(instance) {
      instance.transferBcoupons.call(accounts[1], 10);
      return FedCoup.deployed();
    }).then(function( instance ) {
      assert.equal(instance.balanceOf_B_coupons.call(accounts[0]).valueOf(), 0, "account[0] - 0 wasn't in the B coupons after with initial 0 B balance");
      assert.equal(instance.balanceOf_B_coupons.call(accounts[1]).valueOf(), 0, "account[1] - 0 wasn't in the B coupons after with initial 0 B balance");
    });
  });
*/

  /*
  it("should call a function that depends on a linked library", function() {
    var meta;
    var metaCoinBalance;
    var metaCoinEthBalance;

    return MetaCoin.deployed().then(function(instance) {
      meta = instance;
      return meta.getBalance.call(accounts[0]);
    }).then(function(outCoinBalance) {
      metaCoinBalance = outCoinBalance.toNumber();
      return meta.getBalanceInEth.call(accounts[0]);
    }).then(function(outCoinBalanceEth) {
      metaCoinEthBalance = outCoinBalanceEth.toNumber();
    }).then(function() {
      assert.equal(metaCoinEthBalance, 2 * metaCoinBalance, "Library function returned unexpected function, linkage may be broken");
    });
  });
  it("should send coin correctly", function() {
    var meta;

    // Get initial balances of first and second account.
    var account_one = accounts[0];
    var account_two = accounts[1];

    var account_one_starting_balance;
    var account_two_starting_balance;
    var account_one_ending_balance;
    var account_two_ending_balance;

    var amount = 10;

    return MetaCoin.deployed().then(function(instance) {
      meta = instance;
      return meta.getBalance.call(account_one);
    }).then(function(balance) {
      account_one_starting_balance = balance.toNumber();
      return meta.getBalance.call(account_two);
    }).then(function(balance) {
      account_two_starting_balance = balance.toNumber();
      return meta.sendCoin(account_two, amount, {from: account_one});
    }).then(function() {
      return meta.getBalance.call(account_one);
    }).then(function(balance) {
      account_one_ending_balance = balance.toNumber();
      return meta.getBalance.call(account_two);
    }).then(function(balance) {
      account_two_ending_balance = balance.toNumber();

      assert.equal(account_one_ending_balance, account_one_starting_balance - amount, "Amount wasn't correctly taken from the sender");
      assert.equal(account_two_ending_balance, account_two_starting_balance + amount, "Amount wasn't correctly sent to the receiver");
    });
  });
  */
});
