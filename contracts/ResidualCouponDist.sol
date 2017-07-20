pragma solidity ^0.4.4;

/*
* 
*/
contract ResidualCouponDist {

    /* 
    * residual B coupons which accumulated over the period due to B coupon transfers.
    */
    uint residualBcoupons = 0;

    /* 
    * residual S coupons which accumulated over the period due to B coupon transfers.
    */
    uint residualScoupons = 0;

 
     /*
    * Get balance of residual B coupons.
    */
    function getBalanceOfResidualBcoupons() constant returns(uint residualBcoupons) {
        return residualBcoupons;
    }

    /*
    * Get balance of residual S coupons.
    */
    function getBalanceOfResidualScoupons() constant returns(uint residualScoupons) {
        return residualScoupons;
    }


}