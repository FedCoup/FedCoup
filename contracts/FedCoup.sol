pragma solidity ^0.4.4;
import "zeppelin/token/MintableToken.sol";


contract FedCoup is MintableToken {

    using SafeMath for uint;

    /* residual B coupons which accumulated over the period due to B coupon distribution */
    uint residualBcoupons = 0;

    /* balance of S coupons for each address */
    mapping (address => uint) balance_S_coupons;
    
    /* balance of B coupons for each address */
    mapping (address => uint) balance_B_coupons;
    
    /* event to log coupon creation */
    event CouponsCreated(address indexed owner, uint Scoupons, uint Bcoupons);

    /* event to log accepted B coupons */
    event Accept_B_coupons(address indexed from, address indexed to, uint value);
   
    /* event to log B coupons transfer */
    event Transfer_B_coupons(address indexed from, address indexed to, uint value);

    /* event to log residual B coupons transfer */
    event TransferResidual_B_coupons(address indexed from, address indexed to, uint value);

    /* 
    * Create tokens for given FCC. 
    */
    function createCoupons(uint _FCC) onlyPayloadSize(2 * 32) {

        /* subtract given FCC from sender balance */
        balances[msg.sender] = balances[msg.sender].sub(_FCC);
        
        /* create S coupons */ 
        uint  createdScoupons = _FCC;
        /* add created S coupons to sender */
        balance_S_coupons[msg.sender] = balance_S_coupons[msg.sender].add( createdScoupons );
        
        /* create B coupons and add it to sender */
        uint currentBcoupons = balance_B_coupons[msg.sender];
        uint currentScoupons = balance_S_coupons[msg.sender];
        /* ideal B coupon creation for given _FCC */
        uint  idealBcoupons = _FCC;
        /* ideal S coupon creation for given _FCC */
        uint  idealScoupons = _FCC;

        /* assign ideal B coupons to createdBcoupons */
        uint createdBcoupons = idealBcoupons;

        /* add ideal coupons with current coupons */
        currentBcoupons = currentBcoupons.add( idealBcoupons );
        currentScoupons = currentScoupons.add( idealScoupons );

        if ( currentBcoupons > 0 ) {
            /* bCoupons = (B/S)*_FCC */
            uint couponDist = currentBcoupons.div(currentScoupons);
            /* if S,B coupon distribution <= 1, then multiply with ideal B coupons */
            if ( couponDist <= 1 ) {
                createdBcoupons = couponDist.mul( idealBcoupons );
                residualBcoupons = residualBcoupons.add(idealBcoupons.sub(createdBcoupons));
            } else {
                /* if S,B coupon distribution > 1, then */     
            }             
        }
  
        /* add created B coupons to sender */
        balance_B_coupons[msg.sender] = balance_B_coupons[msg.sender].add( createdBcoupons );

        /* log event */
        CouponsCreated(msg.sender, createdScoupons, createdBcoupons);
    }


    /*
    * Accept B coupons.
    */
    function accept_B_coupons(address _from, uint _Bcoupons) returns (bool success) {
        
        /* substract S balance */
        balance_S_coupons[_from] = balance_S_coupons[_from].sub( _Bcoupons );
    
        /* convert accepted B coupons into FCC equivalent and add it to sender balance */
        balances[msg.sender] = balances[msg.sender].add( _Bcoupons );
        
        /* log event */
        Accept_B_coupons(_from, msg.sender, _Bcoupons);
        
        return true;
    }

    /* Transfer B coupons. 
    *
    */
    function transferBcoupons(address _to, uint _value) onlyPayloadSize(2 * 32) {
        balance_B_coupons[msg.sender] = balance_B_coupons[msg.sender].sub(_value);
        balance_B_coupons[_to] = balance_B_coupons[_to].add(_value);
        /* log event */
        Transfer_B_coupons(msg.sender, _to, _value);
    }

    /*
    * Transfer residual B coupons to entities which integrates FedCoup. 
    * It's investment on entities to integrate FedCoup on their sales lifecycle. 
    */
    function transferResidualBcoupons(address _to, uint _value) onlyPayloadSize(2 * 32) onlyOwner {
        residualBcoupons = residualBcoupons.sub(_value);
        balance_B_coupons[_to] = balance_B_coupons[_to].add(_value);
        /* log event */
        TransferResidual_B_coupons(msg.sender, _to, _value);
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
    * Get balance of residual B coupons.
    */
    function getBalanceOfResidualBcoupons() constant returns(uint residualBcoupons) {
        return residualBcoupons;
    }

}