pragma solidity ^0.4.4;
import "./FCCPrice.sol";
import "./FCCPriceDefault.sol";
import "zeppelin/token/MintableToken.sol";

/*
* Contract for Federation Coupon System.
*/
contract FedCoup is MintableToken {

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

    /* default FCC (fedcoup currency) value as 0.01 USD.  
     * This default value will be used until FCC price ticker available in the exchanges. 
     * If price ticker available, in the next version, the method will be included to pull price data from available exchanges and average of them will be assigned to this variable.
     */
    uint256 FCC_value = 10 finney;  

    /* 
    * constant S,B coupon (federation coupon) price as 0.01 USD. 
    */
    uint256 constant constant_coupon_price = 10 finney;  

    /* residual B coupons which accumulated over the period due to B coupon distribution */
    uint residualBcoupons = 0;

    /* balance of S coupons for each address */
    mapping (address => uint) balance_S_coupons;
    
    /* balance of B coupons for each address */
    mapping (address => uint) balance_B_coupons;
    
    /* 
    * Function to get FCC price. 
    * While FedCoup contract deployment, this function delegated to FCCPriceDefault contract.
    * In future, this function will be delegated to new contract which would determine the FCC price from the exchange data.
    */
    FCCPrice _fCCPriceFunction;

    /* event to log coupon creation */
    event CouponsCreated(address indexed owner, uint Scoupons, uint Bcoupons);

    /* event to log accepted B coupons */
    event Accept_B_coupons(address indexed from, address indexed to, uint value);
   
    /* event to log B coupons transfer */
    event Transfer_B_coupons(address indexed from, address indexed to, uint value);

    /* event to log residual B coupons transfer */
    event TransferResidual_B_coupons(address indexed from, address indexed to, uint value);

    /*
    * FedCoup Constructor.
    */
    function FedCoup() {
        _fCCPriceFunction = FCCPriceDefault(10 finney);
    }

    /* 
    * Create tokens for given FCC. 
    */
    function createCoupons(uint _FCC) onlyPayloadSize(2 * 32) {

        /* subtract given FCC from sender FCC balance */
        balances[msg.sender] = balances[msg.sender].sub( _FCC );
        
        /* get current coupon counts from sender */
        uint currentBcoupons = balance_B_coupons[msg.sender];
        uint currentScoupons = balance_S_coupons[msg.sender];

        /* 
        *  ideal B coupon creation for given _FCC 
        *  
        *  Formula: number of B coupons =
        *  
        *           (given FCC * FCC price)
        *          --------------------------      
        *            constant_coupon_price  
        */
        uint  idealBcoupons = _FCC.mul( _fCCPriceFunction.getFCCPrice() ).div( constant_coupon_price );

        /* 
        *  ideal S coupon creation for given _FCC 
        * 
        *  Formula: number of S coupons =
        * 
        *          (given FCC * FCC price)
        *        ---------------------------   
        *          constant_coupon_price
        */
        uint  idealScoupons = _FCC.mul( _fCCPriceFunction.getFCCPrice() ).div( constant_coupon_price );

        /* 
        * assign ideal B coupons to calculatedBcoupons.
        * If B coupon distribution >= 1 or <= 2, then this ideal coupon direclty goes to the user account.
        */
        uint calculatedBcoupons = idealBcoupons;

        /* 
        * add ideal coupons with current coupons 
        */
        uint idealTotalBcoupons = currentBcoupons.add( idealBcoupons );
        uint idealTotalScoupons = currentScoupons.add( idealScoupons );

        if ( idealTotalBcoupons > 0 ) {
            /* 
            * BCouponDist = (currentBcoupons + idealBcoupons)/ (currentScoupons + idealScoupons))
            */
            uint BCouponDist = idealTotalBcoupons.div(idealTotalScoupons);
            /* if B coupon distribution < 1, then multiply with ideal B coupons */
            if ( BCouponDist < 1 ) {
                /*
                * calculatedBcoupons = BCouponDist*idealBcoupons; 
                */
                calculatedBcoupons = BCouponDist.mul( idealBcoupons );
                /* 
                * add remaining B coupons which is part of ideal B coupons but not added to the calculated B coupons (which direclty goes to the user account) 
                */
                residualBcoupons = residualBcoupons.add(idealBcoupons.sub(calculatedBcoupons));
            } else if ( BCouponDist > 2 ) {
                /* 
                * if B coupon distribution > 2, then following formula will be applied
                * 
                * Formula:  calculatedBcoupons = 
                *    |    (currentBcoupons + idealBcoupons)                                      |
                *    |  ------------------------------------------------------------------------ | * idealBcoupons
                *    |    (currentBcoupons + idealBcoupons) - (currentScoupons + idealScoupons)  |         
                */
                BCouponDist = idealTotalBcoupons.div( idealTotalBcoupons.sub(idealTotalScoupons) );
                calculatedBcoupons = BCouponDist.mul( idealBcoupons );
            }             
        } else {
            /*
            * if ideal total B coupons is 0, then user don't have any balance coupons in the account and user passing 0 as the given FCC.
            * otherwise throw.
            */
            if (idealTotalBcoupons > 0 || idealScoupons > 0 ) {
                throw;
            }
            
        }
  
        /* 
        * add created B coupons to sender 
        */
        balance_B_coupons[msg.sender] = balance_B_coupons[msg.sender].add( calculatedBcoupons );

        /* 
        * add ideal S coupons to sender 
        */
        balance_S_coupons[msg.sender] = balance_S_coupons[msg.sender].add( idealScoupons );

        /* log event */
        CouponsCreated(msg.sender, idealScoupons, calculatedBcoupons);
    }


    /*
    * Accept B coupons.
    */
    function accept_B_coupons(address _from, uint _Bcoupons) onlyPayloadSize(2 * 32) {
        
        /* substract B coupons from the beneficiary account */
        balance_B_coupons[_from] = balance_B_coupons[_from].sub( _Bcoupons );

        /* substract equivalent S coupons from message sender(coupon acceptor) account */
        balance_S_coupons[msg.sender] = balance_S_coupons[msg.sender].sub( _Bcoupons );
    
        /* convert accepted B coupons into FCC equivalent and add it to sender balance */
        balances[msg.sender] = balances[msg.sender].add( _Bcoupons );
        
        /* log event */
        Accept_B_coupons(_from, msg.sender, _Bcoupons);        
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

    /*
    * Set FCC price function to get FCC price.
    */
    function setFCCPriceFunction(address addrFCCPriceFunc) onlyPayloadSize(2 * 32) onlyOwner {
        _fCCPriceFunction = FCCPrice(addrFCCPriceFunc);
    }

    /*
    * 
    */
    function 
}