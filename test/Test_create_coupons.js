var FedCoup = artifacts.require("./FedCoup.sol");

contract('FedCoup', function(accounts) {

  var fedCoupInstance = FedCoup.deployed();

  /* test coupon initial value */
  it("should 0B coupons and 0S coupons in accounts[0] initially", function() {
    return fedCoupInstance.then(function(instance) {
      instance.getBcouponBalances.call(accounts[0]).then(function(noOfBcoupons){
        assert.equal(noOfBcoupons.valueOf(), 0, "0B coupons in accounts[0] is not reflected");
      })
      instance.getScouponBalances.call(accounts[0]).then(function(noOfScoupons){
        assert.equal(noOfScoupons.valueOf(), 0, "0S coupons in accounts[0] is not reflected");
      })      
    })
  });

  /* test B coupon creation first time*/
  it("should create 50B coupons to accounts[0] with 1 FET token", function() {
    return fedCoupInstance.then(function(instance) {
        return instance.createCoupons(1000000000000000000);
    }).then(function(txHash) {
      return fedCoupInstance.then(function(instance){
        instance.getBcouponBalances.call(accounts[0]).then(function(noOfBcoupons){
          assert.equal(noOfBcoupons.valueOf(), 5e+19, "50B coupons in accounts[0] is not reflected");
        }).catch(function(error){
          console.log(error);
        })
        instance.getScouponBalances.call(accounts[0]).then(function(noOfScoupons){
          assert.equal(noOfScoupons.valueOf(), 1e+20, "100S coupons in accounts[0] is not reflected");
        }).catch(function(error){
          console.log(error);
        })        
      })
    })
  });

  /* test coupon creation second time */
  it("should add 50B coupons to accounts[0] for given 1 FET token", function() {
    return fedCoupInstance.then(function(instance) {
        return instance.createCoupons(1000000000000000000);
    }).then(function(txHash) {
      return fedCoupInstance.then(function(instance){
        //100B should be in account[0]
        instance.getBcouponBalances.call(accounts[0]).then(function(noOfBcoupons){
          assert.equal(noOfBcoupons.valueOf(), 1e+20, "100B coupons in accounts[0] is not reflected");
        }).catch(function(error){
          console.log(error);
        })
        //200S should be in account[0]
        instance.getScouponBalances.call(accounts[0]).then(function(noOfScoupons){
          assert.equal(noOfScoupons.valueOf(), 2e+20, "200S coupons in accounts[0] is not reflected");
        }).catch(function(error){
          console.log(error);
        })        
      })
    })
  });

  /* test coupon creation second time */
  it("should add 500B coupons to accounts[0] for given 10 FET token", function() {
    return fedCoupInstance.then(function(instance) {
        return instance.createCoupons(10000000000000000000);
    }).then(function(txHash) {
      return fedCoupInstance.then(function(instance){
        //600B should be in account[0]
        instance.getBcouponBalances.call(accounts[0]).then(function(noOfBcoupons){
          assert.equal(noOfBcoupons.valueOf(), 6e+20, "600B coupons in accounts[0] is not reflected");
        }).catch(function(error){
          console.log(error);
        })
        //1200S should be in account[0]
        instance.getScouponBalances.call(accounts[0]).then(function(noOfScoupons){
          assert.equal(noOfScoupons.valueOf(), 12e+20, "1200S coupons in accounts[0] is not reflected");
        }).catch(function(error){
          console.log(error);
        })        
      })
    })
  });

 
  /* test coupon creation after changing coupon allocation factor */
  it("should add 500B coupons to accounts[0] for given 10 FET token", function() {
    return fedCoupInstance.then(function(instance) {
        return instance.createCoupons(10000000000000000000);
    }).then(function(txHash) {
      return fedCoupInstance.then(function(instance){
        //600B should be in account[0]
        instance.getBcouponBalances.call(accounts[0]).then(function(noOfBcoupons){
          assert.equal(noOfBcoupons.valueOf(), 6e+20, "600B coupons in accounts[0] is not reflected");
        }).catch(function(error){
          console.log(error);
        })
        //1200S should be in account[0]
        instance.getScouponBalances.call(accounts[0]).then(function(noOfScoupons){
          assert.equal(noOfScoupons.valueOf(), 12e+20, "1200S coupons in accounts[0] is not reflected");
        }).catch(function(error){
          console.log(error);
        })        
      })
    })
  });

});
