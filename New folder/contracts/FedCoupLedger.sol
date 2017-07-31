pragma solidity ^0.4.4;

import "zeppelin/token/MintableToken.sol";
import "./CouponTransferCost.sol";
import "./ResidualCouponDist.sol";

/*
* Contract for Federation Coupon System.
*/
contract FedCoupLedger is MintableToken, ResidualCouponDist, CouponTransferCost {

    using SafeMath for uint;

    /*
    * Name of the Federation Coupon System.
    */
    string public name = "FedCoup";

    /* 
    * FedCoup currency symbol. 
    */
    string public symbol = "FCC";

    uint public decimals = 18;

    /* default FCC (fedcoup token) value as 0.01 USD.  
     * This default value will be used until FCC price ticker available in the exchanges. 
     * If price ticker available, in the next version, the method will be included to pull price data from available exchanges and average of them will be assigned to this variable.
     */
    uint256 FCC_value = 10 finney;  

    /* 
    * constant S,B coupon (federation coupon) division factor as 0.01 
    */
    uint256 constant constant_coupon_div_factor = 10 finney;  

    /* 
    * balance of S coupons for each address 
    */
    mapping (address => uint) balance_S_coupons;
    
    /* 
    * balance of B coupons for each address 
    */
    mapping (address => uint) balance_B_coupons;
    
    /*
    *
    */ 
    CouponTransferCost _couponTransferCost;

    /* 
    * event to log coupon creation.
    */
    event CouponsCreated(address indexed owner, uint Bcoupons, uint Scoupons);

    /* 
    * event to log accepted B coupons.
    */
    event Accept_B_coupons(address indexed from, address indexed to, uint value);
   
    /* 
    * event to log accepted S coupons.
    */
    event Accept_S_coupons(address indexed from, address indexed to, uint value);

    /* 
    * event to log B coupons transfer. 
    */
    event Transfer_B_coupons(address indexed from, address indexed to, uint value);

    /* 
    * event to log B coupons transfer. 
    */
    event Transfer_S_coupons(address indexed from, address indexed to, uint value);

    /* 
    * event to log residual B coupons transfer.
    */
    event TransferResidual_B_coupons(address indexed from, address indexed to, uint value);

    /* 
    * event to log residual S coupons transfer.
    */
    event TransferResidual_S_coupons(address indexed from, address indexed to, uint value);    

}