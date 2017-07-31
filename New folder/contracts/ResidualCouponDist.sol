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
    * Transfer residual B coupons to entities which integrates FedCoup. 
    * It's investment on entities to integrate FedCoup on their sales lifecycle. 
    */
    function transferResidualBcoupons(address _to, uint _numberOfBcoupons);

    /*
    * Transfer residual B coupons to entities which integrates FedCoup. 
    * It's investment on entities to integrate FedCoup on their sales lifecycle. 
    */
    function transferResidualScoupons(address _to, uint _numberOfScoupons);

    /*
    * Get balance of residual B coupons.
    */
    function getBalanceOfResidualBcoupons() constant returns(uint residualBcoupons);

    /*
    * Get balance of residual S coupons.
    */
    function getBalanceOfResidualScoupons() constant returns(uint residualScoupons);


}