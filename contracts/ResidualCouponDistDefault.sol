pragma solidity ^0.4.4;

/*
* 
*/
contract ResidualCouponDistDefault is ResidualCouponDist {

    /*
    * Transfer residual B coupons to entities which integrates FedCoup. 
    * It's investment on entities to integrate FedCoup on their sales lifecycle. 
    */
    function transferResidualBcoupons(address _to, uint _numberOfBcoupons) onlyPayloadSize(2 * 32) onlyOwner {
        /*
        * substract transfered _numberOfBcoupons from sender's account.
        */      
        residualBcoupons = residualBcoupons.sub( _numberOfBcoupons );

        /*
        * add _numberOfBcoupons to receiver's account.
        */
        balance_B_coupons[_to] = balance_B_coupons[_to].add(_numberOfBcoupons);

        /* 
        * log event. 
        */
        TransferResidual_B_coupons(msg.sender, _to, _numberOfBcoupons);
    } 
 
    /*
    * Transfer residual B coupons to entities which integrates FedCoup. 
    * It's investment on entities to integrate FedCoup on their sales lifecycle. 
    */
    function transferResidualScoupons(address _to, uint _numberOfScoupons) onlyPayloadSize(2 * 32) onlyOwner {

        /*
        * substract transfered _numberOfScoupons from sender's account.
        */ 
        residualScoupons = residualScoupons.sub( _numberOfScoupons );

        /*
        * add _numberOfScoupons to receiver's account.
        */
        balance_S_coupons[_to] = balance_S_coupons[_to].add( _numberOfScoupons );

        /* 
        * log event. 
        */
        TransferResidual_B_coupons(msg.sender, _to, _numberOfScoupons);
    }

}