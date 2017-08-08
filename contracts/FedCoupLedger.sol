pragma solidity ^0.4.4;

import "zeppelin/token/MintableToken.sol";


/*
* Contract for Federation Coupon System.
*/
contract FedCoupLedger is MintableToken {

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

    /* 
    * constant S,B coupon (federation coupon) division factor as 0.01 
    */
    uint constant constant_coupon_div_factor = 100 ether;  

    /* 
    * balance of S coupons for each address 
    */
    mapping (address => uint) balance_S_coupons;
    
    /* 
    * balance of B coupons for each address 
    */
    mapping (address => uint) balance_B_coupons;

    uint B_coupon_allocation_factor = 90;
    
    uint S_coupon_allocation_factor = 100; 

    /* 
    * residual B coupons which accumulated over the period due to B coupon transfers.
    */
    uint residualBcoupons = 0;

    /* 
    * residual S coupons which accumulated over the period due to B coupon transfers.
    */
    uint residualScoupons = 0;

    /*
    * Cost of B coupon (in percentage) when transfer to other user.  
    * This cost necessary, otherwise B coupon will go on circulation loop and it might go on in own curreny mode. 
    * Using this cost, B coupon crunched back to the system if transfer happens continuously without accepting coupons.
    */
    uint transferCostBcoupon = 90;

    /*
    * Cost of S coupon (in percentage) when transfer to other user.  
    * This cost necessary to motivate users to sell products (with coupons) instead of transfering S coupons.
    * Using this cost, S coupon crunched back to the system if transfer happens continuously without accepting coupons.
    */
    uint transferCostScoupon = 1;

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

    address public fedCoupContract;

    modifier onlyFedCoup() {
        if (msg.sender != fedCoupContract) {
          throw;
        }
        _;
    }

    function getConstantCouponDivFactor() constant external returns (uint) {
        return constant_coupon_div_factor; 
    }    

    function getTokenBalances(address _addr) constant external returns (uint) {
        return balances[ _addr ]; 
    }

    function addTokenBalances(address _to, uint _numberOfTokens) onlyPayloadSize(2 * 32) onlyFedCoup external {
        balances[ _to ] = balances[ _to ].add( _numberOfTokens );
    }

    function subTokenBalances(address _from, uint _numberOfTokens) onlyPayloadSize(2 * 32) onlyFedCoup external {
        balances[ _from ] = balances[ _from ].sub( _numberOfTokens );
    }

    function getBcouponBalances(address _addr) constant external returns (uint) {
        return balance_B_coupons[ _addr ];
    }

    function addBcouponBalances(address _to, uint _numberOfBcoupons) onlyPayloadSize(2 * 32) onlyFedCoup external {
        balance_B_coupons[ _to ] = balance_B_coupons[ _to ].add( _numberOfBcoupons );
    }

    function subBcouponBalances(address _from, uint _numberOfBcoupons) onlyPayloadSize(2 * 32) onlyFedCoup external {
        balance_B_coupons[ _from ] = balance_B_coupons[ _from ].sub( _numberOfBcoupons );
    }

    function getScouponBalances(address _addr) constant external returns (uint) {
        return balance_S_coupons[ _addr ];
    } 

    function addScouponBalances(address _to, uint _numberOfScoupons) onlyPayloadSize(2 * 32) onlyFedCoup external {
        balance_S_coupons[ _to ] = balance_S_coupons[ _to ].add( _numberOfScoupons );
    }

    function subScouponBalances(address _from, uint _numberOfScoupons) onlyPayloadSize(2 * 32) onlyFedCoup external {
        balance_S_coupons[ _from ] = balance_S_coupons[ _from ].sub( _numberOfScoupons );
    }

    function addResidualBcouponBalances(uint _numberOfBcoupons) onlyPayloadSize(2 * 32) onlyFedCoup external {
        residualBcoupons = residualBcoupons.add( _numberOfBcoupons );
    }

    function addResidualScouponBalances(uint _numberOfScoupons) onlyPayloadSize(2 * 32) onlyFedCoup external {
        residualScoupons = residualScoupons.add( _numberOfScoupons );
    }

    function getBcouponAllocationFactor() constant external returns (uint) {
        return B_coupon_allocation_factor;
    } 

    function getScouponAllocationFactor() constant external returns (uint) {
        return S_coupon_allocation_factor;
    }

    function getBcouponTransferCost() constant external returns (uint) {
        return transferCostBcoupon;
    }

    function getScouponTransferCost() constant external returns (uint) {
        return transferCostScoupon;
    }    

    function logCouponCreationEvent(address _addr, uint _numberOfBcoupons, uint _numberOfScoupons) onlyPayloadSize(2 * 32) onlyFedCoup external {
        CouponsCreated(msg.sender, _numberOfBcoupons, _numberOfScoupons);
    }

    function logAcceptBcouponsEvent(address _from, address _to, uint _numberOfBcoupons) onlyPayloadSize(2 * 32) onlyFedCoup external {
        Accept_B_coupons(_from, _to, _numberOfBcoupons);
    }

   function logAcceptScouponsEvent(address _from, address _to, uint _numberOfScoupons) onlyPayloadSize(2 * 32) onlyFedCoup external {
        Accept_S_coupons(_from, _to, _numberOfScoupons);
    }

    function logTransferBcouponsEvent(address _from, address _to, uint _numberOfBcoupons) onlyPayloadSize(2 * 32) onlyFedCoup external {
        Transfer_B_coupons(_from, _to, _numberOfBcoupons);
    }

    function logTransferScouponsEvent(address _from, address _to, uint _numberOfScoupons) onlyPayloadSize(2 * 32) onlyFedCoup external {
        Transfer_B_coupons(_from, _to, _numberOfScoupons);
    }

    function logTransferResidualBcouponsEvent(address _from, address _to, uint _numberOfBcoupons) onlyPayloadSize(2 * 32) onlyFedCoup external {
        TransferResidual_B_coupons(_from, _to, _numberOfBcoupons);
    }

    function logTransferResidualScouponsEvent(address _from, address _to, uint _numberOfScoupons) onlyPayloadSize(2 * 32) onlyFedCoup external {
        TransferResidual_S_coupons(_from, _to, _numberOfScoupons);
    }

}