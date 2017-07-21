pragma solidity ^0.4.4;

/*
* Coupon transfer costs.
*/
contract CouponCostFunction {

    /*
    * Cost of B coupon (in percentage) when transfer to other user.  
    * This cost necessary, otherwise B coupon will go on circulation loop and it might go on in own curreny mode. 
    * Using this cost, B coupon crunched back to the system if transfer happens continuously without accepting coupons.
    */
    uint transferCostBcoupon = 1;

    /*
    * Cost of S coupon (in percentage) when transfer to other user.  
    * This cost necessary to motivate users to sell products (with coupons) instead of transfering S coupons.
    * Using this cost, S coupon crunched back to the system if transfer happens continuously without accepting coupons.
    */
    uint transferCostScoupon = 90;
 
    /*
    * 
    */
    function setBcouponTransferCost(uint cost);

    /*
    *
    */
    function setScouponTransferCost(uint cost);
}