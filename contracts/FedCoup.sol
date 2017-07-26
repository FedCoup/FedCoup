pragma solidity ^0.4.4;

import "./FedCoupLedger.sol";


/*
* Contract for Federation Coupon System.
*/
contract FedCoup is FedCoupLedger {

    /*
    * FedCoup Constructor.
    */
    function FedCoup() {

    }

    /* 
    * Create tokens for given FCC. 
    *         _FCC : given FedCoup curreny (1FCC equal to 1 ether with respect to number format)
    */
    function createCoupons(uint _FCC) onlyPayloadSize(2 * 32) {

        /* subtract given FCC from sender FCC balance */
        balances[msg.sender] = balances[msg.sender].sub( _FCC );
        
        /* 
        *  B coupon creation for given _FCC 
        *  
        *  Formula: number of B coupons =
        *  
        *           (given FCC * FCC price)
        *          --------------------------      
        *            constant_coupon_price  
        */
        uint  newBcoupons = _FCC.mul( _fCCPriceFunction.getFCCPrice() ).div( constant_coupon_price );

        /* 
        *  S coupon creation for given _FCC 
        * 
        *  Formula: number of S coupons =
        * 
        *          (given FCC * FCC price)
        *        ---------------------------   
        *          constant_coupon_price
        */
        uint  newScoupons = _FCC.mul( _fCCPriceFunction.getFCCPrice() ).div( constant_coupon_price );


        /* 
        * add new coupons with existing coupon balance 
        */
        balance_B_coupons[msg.sender] = balance_B_coupons[msg.sender].add( newBcoupons );
        balance_S_coupons[msg.sender] = balance_S_coupons[msg.sender].add( newScoupons );

        /* log event */
        CouponsCreated(msg.sender, newBcoupons, newScoupons);
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
        balance_B_coupons[_from] = balance_B_coupons[_from].sub( _numberOfBcoupons );

        /* 
        * substract equivalent S coupons from message sender(coupon acceptor) account.
        */
        balance_S_coupons[msg.sender] = balance_S_coupons[msg.sender].sub( _numberOfBcoupons );
    
        /* 
        * convert accepted B coupons into FCC equivalent and add it to sender balance.
        * 
        *  Formula: FCC =
        *  
        *           (_numberOfBcoupons * constant_coupon_price)
        *          ---------------------------------------------      
        *                           FCC price  
        *            
        */
        uint _numberOfFCC = _numberOfBcoupons.mul( constant_coupon_price ).div( _fCCPriceFunction.getFCCPrice() );

        /*
        * add calcualated FCC to acceptor's account.
        */
        balances[msg.sender] = balances[msg.sender].add( _numberOfFCC );
        
        /* 
        * log event. 
        */
        Accept_B_coupons(_from, msg.sender, _numberOfBcoupons);        
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
        balance_B_coupons[msg.sender] = balance_B_coupons[msg.sender].sub(_numberOfBcoupons);

        /*
        * calculate transfer cost.
        * Formula:
        *            transferCost = (1/100) * _numberOfBcoupons 
        */
        uint transferCost =  _numberOfBcoupons.div( 100 ).mul(_couponCostFunction.getBcouponTransferCost());

        /*
        * add transfer cost to residual B coupons.
        */
        residualBcoupons = residualBcoupons.add(transferCost);

        /*
        * subtract transfer cost from given _numberOfBcoupons and add it to the TO account.
        */
        balance_B_coupons[_to] = balance_B_coupons[_to].add( _numberOfBcoupons.sub(transferCost) );

        /* 
        * log event 
        */
        Transfer_B_coupons(msg.sender, _to, _numberOfBcoupons);
    }

    /* 
    * Transfer S coupons. 
    */
    function transferScoupons(address _to, uint _numberOfScoupons) onlyPayloadSize(2 * 32) {

        /*
        * substract _numberOfScoupons from sender account.
        */
        balance_S_coupons[msg.sender] = balance_S_coupons[msg.sender].sub(_numberOfScoupons);

        /*
        * calculate transfer cost.
        * Formula:
        *            transferCost = (1/100) * _numberOfScoupons 
        */
        uint transferCost =  _numberOfScoupons.div( 100 ).mul(_couponCostFunction.getScouponTransferCost());

        /*
        * add transfer cost to residual S coupons.
        */
        residualScoupons = residualScoupons.add(transferCost);

        /*
        * subtract transfer cost from given _numberOfBcoupons and add it to the TO account.
        */
        balance_S_coupons[_to] = balance_S_coupons[_to].add(_numberOfScoupons.sub(transferCost));

        /* 
        * log event.
        */
        Transfer_S_coupons(msg.sender, _to, _numberOfScoupons);
    }

    /*
    * Get balance of S coupons.
    */
    function balanceOf_S_coupons(address _owner) constant returns (uint Sbalance) {
        return balance_S_coupons[_owner];
    }

    /*
    * Get balance of B coupons.
    */
    function balanceOf_B_coupons(address _owner) constant returns (uint Bbalance) {
        return balance_B_coupons[_owner];
    }    

    /*
    * Set FCC price function to get FCC price.
    */
    function setFCCPriceFunction(address addrFCCPriceFunc) onlyPayloadSize(2 * 32) onlyOwner {
        _fCCPriceFunction = FCCPrice(addrFCCPriceFunc);
    }

    /*
    * 
    */
    
    function setCouponCostFunction(address addrCouponCostFunction) onlyPayloadSize(2 * 32) onlyOwner {
        _couponCostFunction = CouponCostFunction(addrCouponCostFunction);
    }
    

}