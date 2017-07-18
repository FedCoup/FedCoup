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

    /* 
    * residual B coupons which accumulated over the period due to B coupon transfers.
    */
    uint residualBcoupons = 0;

    /* 
    * residual S coupons which accumulated over the period due to B coupon transfers.
    */
    uint residualScoupons = 0;

    /* 
    * balance of S coupons for each address 
    */
    mapping (address => uint) balance_S_coupons;
    
    /* 
    * balance of B coupons for each address 
    */
    mapping (address => uint) balance_B_coupons;
    
    /* 
    * Function to get FCC price. 
    * While FedCoup contract deployment, this function delegated to FCCPriceDefault contract.
    * In future, this function will be delegated to new contract which would determine the FCC price from the exchange data.
    */
    FCCPrice _fCCPriceFunction;

    /*
    * Cost of B coupon (in percentage) when transfer to other user.  
    * This cost necessary, otherwise B coupon will go on circulation loop and it might go on in own curreny mode. 
    * Using this cost, B coupon crunched back to the system if transfer happens continuously without accepting coupons.
    */
    uint TransferCostBcoupon = 1;

    /*
    * Cost of S coupon (in percentage) when transfer to other user.  
    * This cost necessary to motivate users to sell products (with coupons) instead of transfering S coupons.
    * Using this cost, S coupon crunched back to the system if transfer happens continuously without accepting coupons.
    */
    uint TransferCostScoupon = 1;

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

    /*
    * FedCoup Constructor.
    */
    function FedCoup() {
        _fCCPriceFunction = FCCPriceDefault(10 finney);
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
        uint transferCost =  _numberOfBcoupons.div( 100 ).mul(TransferCostBcoupon);

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
        uint transferCost =  _numberOfScoupons.div( 100 ).mul(TransferCostScoupon);

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
    * Transfer residual B coupons to entities which integrates FedCoup. 
    * It's investment on entities to integrate FedCoup on their sales lifecycle. 
    */
    function transferResidualBcoupons(address _to, uint _numberOfBcoupons) onlyPayloadSize(2 * 32) onlyOwner {
        residualBcoupons = residualBcoupons.sub(_numberOfBcoupons);
        balance_B_coupons[_to] = balance_B_coupons[_to].add(_numberOfBcoupons);
        /* log event */
        TransferResidual_B_coupons(msg.sender, _to, _numberOfBcoupons);
    } 
 
    /*
    * Transfer residual B coupons to entities which integrates FedCoup. 
    * It's investment on entities to integrate FedCoup on their sales lifecycle. 
    */
    function transferResidualScoupons(address _to, uint _numberOfScoupons) onlyPayloadSize(2 * 32) onlyOwner {
        residualScoupons = residualScoupons.sub(_numberOfScoupons);
        balance_S_coupons[_to] = balance_S_coupons[_to].add(_numberOfScoupons);
        /* log event */
        TransferResidual_B_coupons(msg.sender, _to, _numberOfScoupons);
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
    
}