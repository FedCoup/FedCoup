pragma solidity ^0.4.11;

import "zeppelin/ownership/Ownable.sol";
import "zeppelin/token/StandardToken.sol";


/*
* Contract for Federation Coupon System.
*/
contract FedCoup is StandardToken, Ownable {

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
    uint coupon_mul_factor = 100;  

    /* 
    * balance of S coupons for each address 
    */
    mapping (address => uint) balance_S_coupons;
    
    /* 
    * balance of B coupons for each address 
    */
    mapping (address => uint) balance_B_coupons;

    mapping (address => mapping (address => uint)) allowed_B_coupons;

    uint B_coupon_allocation_factor = 90;
    
    uint S_coupon_allocation_factor = 100; 

    /*
    * Whenever coupon created using FedTokens, those tokens will be added here. 
    * When B coupons accepted with S coupons, the equivalent FedTokens will be substracted here. 
    */
    uint couponizedFedTokens = 0;

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

    event ApprovalBcoupons(address indexed owner, address indexed acceptor, uint value);

    /* 
    * Create coupons for given number of FedCoup tokens. 
    *         _numberOfTokens : given FedCoup token (1 FedCoup token equal to 1 ether with respect to number format)
    */
    function createCoupons(uint _numberOfTokens) onlyPayloadSize(2 * 32) external {

        /* subtract given token from sender token balance */
        balances[ msg.sender ] = balances[ msg.sender ].sub( _numberOfTokens );

        /* 
        *  B coupon creation for given _numberOfTokens 
        *  
        *  Formula: number of B coupons =
        *  
        *                B coupon allocation factor * given _numberOfTokens * coupon_mul_factor
        */
        uint  newBcoupons = B_coupon_allocation_factor.mul( _numberOfTokens.mul( coupon_mul_factor ));

        /* 
        *  S coupon creation for given _numberOfTokens 
        * 
        *  Formula: number of S coupons =
        * 
        *               S coupon allocation factor * given _numberOfTokens * coupon_mul_factor
        */
        uint  newScoupons = S_coupon_allocation_factor.mul( _numberOfTokens.mul( coupon_mul_factor ));


        /* 
        * add new coupons with existing coupon balance 
        */
        balance_B_coupons[ msg.sender ] = balance_B_coupons[ msg.sender ].add( newBcoupons );
        balance_S_coupons[ msg.sender ] = balance_S_coupons[ msg.sender ].add( newScoupons );

        /* log event */
        CouponsCreated(msg.sender, newBcoupons, newScoupons);
    }


    /*
    * accept B coupons.
    *      _from : address of the coupon giver.
    *      _numberOfBcoupons : number of B coupons (1B coupon equal to 1 ether with respect to format)
    */
    function accept_B_coupons(address _from, uint _numberOfBcoupons) onlyPayloadSize(2 * 32) external {
        
        /*
        * Restrict if message sender and from address are same. 
        * Same user cannot accept his own B coupons. The B acceptance should come from other users.
        */
        if (msg.sender == _from ) {
            throw;
        }

        /*
        * The B coupons which has to be accepted should be allowed by the _from address.
        */
        var _allowance = allowed_B_coupons[_from][msg.sender];

        /* 
        * substract B coupons from the giver account.
        */
        balance_B_coupons[ _from ] = balance_B_coupons[ _from ].sub( _numberOfBcoupons );

        /* 
        * substract equivalent S coupons from message sender(coupon acceptor) account.
        */
        balance_S_coupons[ msg.sender ] = balance_S_coupons[ msg.sender ].sub( _numberOfBcoupons );

        /* 
        * convert accepted B coupons into equivalent FedCoup tokens and add it to sender balance.
        * 
        *  Formula: number of tokens =
        *  
        *                _numberOfBcoupons
        *          ------------------------------      
        *                coupon_mul_factor
        *            
        */
        uint _numberOfTokens = _numberOfBcoupons.div( coupon_mul_factor );

        /*
        * add calcualated tokens to acceptor's account.
        */
        balances[ msg.sender ] = balances[ msg.sender ].add( _numberOfTokens );

        /*
        * substract allowed_B_coupons for the accepted _numberOfBcoupons.
        */
        allowed_B_coupons[_from][msg.sender] = _allowance.sub(_numberOfBcoupons);

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
    function transferBcoupons(address _to, uint _numberOfBcoupons) onlyPayloadSize(2 * 32) external {

        /*
        * substract _numberOfBcoupons from sender account.
        */
        balance_B_coupons[ msg.sender ] = balance_B_coupons[ msg.sender ].sub( _numberOfBcoupons );

        /*
        * calculate transfer cost.
        * Formula:  B coupon transferCost =
        *
        *                    B coupon transfer cost (in percentage) * _numberOfBcoupons
        *                   -----------------------------------------------------------
        *                                            100 
        */
        uint transferCost =  _numberOfBcoupons.mul( transferCostBcoupon ).div( 100 );

        /*
        * add transfer cost to residual B coupons.
        */
        residualBcoupons = residualBcoupons.add( transferCost );

        /*
        * subtract transfer cost from given _numberOfBcoupons and add it to the TO account.
        */
        balance_B_coupons[ _to ] = balance_B_coupons[ _to ].add( _numberOfBcoupons.sub(transferCost) );

        /* 
        * log event 
        */
        Transfer_B_coupons(msg.sender, _to, _numberOfBcoupons);
    }

    /* 
    * Transfer S coupons. 
    */
    function transferScoupons(address _to, uint _numberOfScoupons) onlyPayloadSize(2 * 32) external {

        /*
        * substract _numberOfScoupons from sender account.
        */
        balance_S_coupons[ msg.sender ] = balance_S_coupons[ msg.sender ].sub( _numberOfScoupons );

        /*
        * calculate transfer cost.
        * Formula:  S coupon transferCost =
        *
        *                    S coupon transfer cost (in percentage) * _numberOfScoupons
        *                   -----------------------------------------------------------
        *                                            100 
        */        
        uint transferCost =  _numberOfScoupons.div( 100 ).mul( transferCostScoupon );

        /*
        * add transfer cost to residual S coupons.
        */
        residualScoupons = residualScoupons.add( transferCost );    

        /*
        * subtract transfer cost from given _numberOfScoupons and add it to the TO account.
        */
        balance_S_coupons[ _to ] = balance_S_coupons[ _to ].add( _numberOfScoupons.sub(transferCost) );

        /* 
        * log event.
        */
        Transfer_S_coupons(msg.sender, _to, _numberOfScoupons);
    }

    /*
    * Transfer residual B coupons to entities which integrates FedCoup. 
    * It's investment on entities to integrate FedCoup on their sales lifecycle. 
    */
    function transferResidualBcoupons(address _to, uint _numberOfBcoupons) external onlyOwner {
        /*
        * substract transfered _numberOfBcoupons from sender's account.
        */      
        residualBcoupons = residualBcoupons.sub( _numberOfBcoupons );

        /*
        * add _numberOfBcoupons to receiver's account.
        */
        balance_B_coupons[ _to ] = balance_B_coupons[ _to ].add( _numberOfBcoupons );

        /* 
        * log event. 
        */
        TransferResidual_B_coupons(msg.sender, _to, _numberOfBcoupons);
    } 
 
    /*
    * Transfer residual B coupons to entities which integrates FedCoup. 
    * It's investment on entities to integrate FedCoup on their sales lifecycle. 
    */
    function transferResidualScoupons(address _to, uint _numberOfScoupons) external onlyOwner {

        /*
        * substract transfered _numberOfScoupons from sender's account.
        */
        residualScoupons = residualScoupons.sub( _numberOfScoupons );

        /*
        * add _numberOfScoupons to receiver's account.
        */
        balance_S_coupons[ _to ] = balance_S_coupons[ _to ].add( _numberOfScoupons );

        /* 
        * log event. 
        */
        TransferResidual_B_coupons(msg.sender, _to, _numberOfScoupons);
    }

    /*
    * Approve B coupons
    * 
    * Parameters:
    *       _acceptor: address of the acceptor.
    *       _Bcoupons: number of B coupons has to be accepted from message sender by acceptor.
    */
    function approveBcoupons(address _acceptor, uint _Bcoupons) external {
        allowed_B_coupons[msg.sender][_acceptor].add( _Bcoupons );
        ApprovalBcoupons(msg.sender, _acceptor, _Bcoupons);
    }    

    /*
    * Get B coupon allowance from 
    *
    * Parameters:
    *       _from: address of the B coupon sender.
    *       _acceptor: address of the B coupon acceptor.
    */
    function allowanceBcoupons(address _from, address _acceptor) constant external returns (uint remaining) {
        return allowed_B_coupons[_from][_acceptor];
    }

    function getCouponMulFactor() constant external returns (uint) {
        return coupon_mul_factor; 
    }    

    function setCouponMulFactor(uint couponMulFactor) external onlyOwner {
        coupon_mul_factor = couponMulFactor; 
    } 

    function getTokenBalances(address _addr) constant external returns (uint) {
        return balances[ _addr ]; 
    }

    function getBcouponAllocationFactor() constant external returns (uint) {
        return B_coupon_allocation_factor;
    } 

    function setBcouponAllocationFactor(uint BcouponAllocFactor) external onlyOwner {
        B_coupon_allocation_factor = BcouponAllocFactor;
    } 

    function getScouponAllocationFactor() constant external returns (uint) {
        return S_coupon_allocation_factor;
    }

    function setScouponAllocationFactor(uint ScouponAllocFactor) external onlyOwner {
        S_coupon_allocation_factor = ScouponAllocFactor;
    }

    function getBcouponTransferCost() constant external returns (uint) {
        return transferCostBcoupon;
    }

    function setBcouponTransferCost(uint transferCostBcoup) external onlyOwner {
        transferCostBcoupon = transferCostBcoup;
    }    

    function getScouponTransferCost() constant external returns (uint) {
        return transferCostScoupon;
    }     

    function setScouponTransferCost(uint transferCostScoup) external onlyOwner {
        transferCostScoupon = transferCostScoup;
    }

    function getBcouponBalances(address _addr) constant external returns (uint) {
        return balance_B_coupons[ _addr ];
    }

    function getScouponBalances(address _addr) constant external returns (uint) {
        return balance_S_coupons[ _addr ];
    }   

    function getBalanceOfResidualBcoupons() constant external returns (uint) {
        return residualBcoupons;
    }


}