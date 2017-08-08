pragma solidity ^0.4.4;

import "zeppelin/ownership/Ownable.sol";
import "zeppelin/SafeMath.sol";
import "./FedCoupLedger.sol";

/*
* Contract for Federation Coupon System.
*/
contract FedCoup is Ownable {

    using SafeMath for uint;

    FedCoupLedger fedCoupLedger;

    /*
    * Fix for the ERC20 short address attack  
    */
    modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
    }

    /*
    * FedCoup Constructor.
    */
    function FedCoup(address _fedCoupLedgerAddr) {
        fedCoupLedger = FedCoupLedger(_fedCoupLedgerAddr);
    }


    /* 
    * Create tokens for given FCC. 
    *         _FCC : given FedCoup curreny (1FCC equal to 1 ether with respect to number format)
    */
    function createCoupons(uint _numberOfTokens) onlyPayloadSize(2 * 32) {

        /* subtract given token from sender token balance */
        fedCoupLedger.subTokenBalances(msg.sender, _numberOfTokens );

        /* 
        *  B coupon creation for given _numberOfTokens 
        *  
        *  Formula: number of B coupons =
        *  
        *                B coupon allocation factor * given _numberOfTokens * constant_coupon_div_factor
        */
        uint  newBcoupons = fedCoupLedger.getBcouponAllocationFactor().mul( _numberOfTokens.mul( fedCoupLedger.getConstantCouponDivFactor() ));

        /* 
        *  S coupon creation for given _numberOfTokens 
        * 
        *  Formula: number of S coupons =
        * 
        *               S coupon allocation factor * given _numberOfTokens * constant_coupon_div_factor
        */
        uint  newScoupons = fedCoupLedger.getBcouponAllocationFactor().mul( _numberOfTokens.mul( fedCoupLedger.getConstantCouponDivFactor() ));


        /* 
        * add new coupons with existing coupon balance 
        */
        fedCoupLedger.addBcouponBalances( msg.sender, newBcoupons );
        fedCoupLedger.addScouponBalances( msg.sender, newScoupons );

        /* log event */
        fedCoupLedger.logCouponCreationEvent(msg.sender, newBcoupons, newScoupons);
    }


    /*
    * accept B coupons.
    *      _from : address of the coupon giver.
    *      _numberOfBcoupons : number of B coupons (1B coupon equal to 1 ether with respect to format)
    */
    function accept_B_coupons(address _from, uint _numberOfBcoupons) onlyPayloadSize(2 * 32) {
        
        /* 
        * substract B coupons from the giver account.
        */
        fedCoupLedger.subBcouponBalances(_from, _numberOfBcoupons);

        /* 
        * substract equivalent S coupons from message sender(coupon acceptor) account.
        */
        fedCoupLedger.subScouponBalances(msg.sender, _numberOfBcoupons);

        /* 
        * convert accepted B coupons into FCC equivalent and add it to sender balance.
        * 
        *  Formula: number of tokens =
        *  
        *                _numberOfBcoupons
        *          ------------------------------      
        *            constant_coupon_div_factor
        *            
        */
        uint _numberOfTokens = _numberOfBcoupons.div( fedCoupLedger.getConstantCouponDivFactor() );

        /*
        * add calcualated tokens to acceptor's account.
        */
        fedCoupLedger.addTokenBalances(msg.sender, _numberOfTokens);

        /* 
        * log event. 
        */
        fedCoupLedger.logAcceptBcouponsEvent(_from, msg.sender, _numberOfBcoupons);        
    }

    /* 
    * Transfer B coupons. 
    *       _to: To address where B coupons has to be send
    *       _numberOfBcoupons: number of B coupons (1 coupon equal to 1 ether)
    */
    function transferBcoupons(address _to, uint _numberOfBcoupons) onlyPayloadSize(2 * 32) {

        /*
        * substract _numberOfBcoupons from sender account.
        */
        fedCoupLedger.subBcouponBalances(msg.sender, _numberOfBcoupons);

        /*
        * calculate transfer cost.
        * Formula:  B coupon transferCost =
        *
        *                    B coupon transfer cost (in percentage) * _numberOfBcoupons
        *                   -----------------------------------------------------------
        *                                            100 
        */
        uint transferCost =  _numberOfBcoupons.mul(fedCoupLedger.getBcouponTransferCost()).div( 100 );

        /*
        * add transfer cost to residual B coupons.
        */
        fedCoupLedger.addResidualBcouponBalances(transferCost);

        /*
        * subtract transfer cost from given _numberOfBcoupons and add it to the TO account.
        */
        fedCoupLedger.addBcouponBalances(_to, _numberOfBcoupons.sub(transferCost));        

        /* 
        * log event 
        */
        fedCoupLedger.logTransferBcouponsEvent(msg.sender, _to, _numberOfBcoupons);
    }

    /* 
    * Transfer S coupons. 
    */
    function transferScoupons(address _to, uint _numberOfScoupons) onlyPayloadSize(2 * 32) {

        /*
        * substract _numberOfScoupons from sender account.
        */
        fedCoupLedger.subScouponBalances(msg.sender, _numberOfScoupons);

        /*
        * calculate transfer cost.
        * Formula:  S coupon transferCost =
        *
        *                    S coupon transfer cost (in percentage) * _numberOfScoupons
        *                   -----------------------------------------------------------
        *                                            100 
        */        
        uint transferCost =  _numberOfScoupons.div( 100 ).mul(fedCoupLedger.getScouponTransferCost());

        /*
        * add transfer cost to residual S coupons.
        */
        fedCoupLedger.residualScoupons = fedCoupLedger.residualScoupons.add(transferCost);

        /*
        * subtract transfer cost from given _numberOfBcoupons and add it to the TO account.
        */
        fedCoupLedger.balance_S_coupons[_to] = fedCoupLedger.balance_S_coupons[_to].add(_numberOfScoupons.sub(transferCost));

        /* 
        * log event.
        */
        fedCoupLedger.logTransferScouponsEvent(msg.sender, _to, _numberOfScoupons);
    }

    /*
    * Transfer residual B coupons to entities which integrates FedCoup. 
    * It's investment on entities to integrate FedCoup on their sales lifecycle. 
    */
    function transferResidualBcoupons(address _to, uint _numberOfBcoupons) onlyOwner {
        /*
        * substract transfered _numberOfBcoupons from sender's account.
        */      
        fedCoupLedger.residualBcoupons = fedCoupLedger.residualBcoupons.sub( _numberOfBcoupons );

        /*
        * add _numberOfBcoupons to receiver's account.
        */
        fedCoupLedger.balance_B_coupons[_to] = fedCoupLedger.balance_B_coupons[_to].add(_numberOfBcoupons);

        /* 
        * log event. 
        */
        fedCoupLedger.logTransferResidualBcouponsEvent(msg.sender, _to, _numberOfBcoupons);
    } 
 
    /*
    * Transfer residual B coupons to entities which integrates FedCoup. 
    * It's investment on entities to integrate FedCoup on their sales lifecycle. 
    */
    function transferResidualScoupons(address _to, uint _numberOfScoupons) onlyOwner {

        /*
        * substract transfered _numberOfScoupons from sender's account.
        */ 
        fedCoupLedger.residualScoupons = fedCoupLedger.residualScoupons.sub( _numberOfScoupons );

        /*
        * add _numberOfScoupons to receiver's account.
        */
        fedCoupLedger.balance_S_coupons[_to] = fedCoupLedger.balance_S_coupons[_to].add( _numberOfScoupons );

        /* 
        * log event. 
        */
        fedCoupLedger.logTransferResidualScouponsEvent(msg.sender, _to, _numberOfScoupons);
    }

   /*
    * Get balance of residual B coupons.
    */
    function getBalanceOfResidualBcoupons() constant returns(uint residualBcoupons) {
        return fedCoupLedger.residualBcoupons;
    }

    /*
    * Get balance of residual S coupons.
    */
    function getBalanceOfResidualScoupons() constant returns(uint residualScoupons) {
        return fedCoupLedger.residualScoupons;
    }

    /*
    * Get balance of S coupons.
    */
    function balanceOf_S_coupons(address _owner) constant returns (uint Sbalance) {
        return fedCoupLedger.balance_S_coupons[_owner];
    }

    /*
    * Get balance of B coupons.
    */
    function balanceOf_B_coupons(address _owner) constant returns (uint Bbalance) {
        return fedCoupLedger.balance_B_coupons[_owner];
    }    

    /*
    * 
    */
    function setBcouponTransferCost(uint cost) onlyOwner {
        fedCoupLedger.transferCostBcoupon = cost; 
    }

    /*
    *
    */
    function setScouponTransferCost(uint cost) onlyOwner {
        fedCoupLedger.transferCostScoupon = cost;
    }

    /*
    * 
    */
    function getBcouponTransferCost() constant returns (uint) {
        return fedCoupLedger.transferCostBcoupon;
    }

    /*
    *
    */
    function getScouponTransferCost() constant returns (uint) {
        return fedCoupLedger.transferCostScoupon;
    }

}