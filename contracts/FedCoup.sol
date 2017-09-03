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

    mapping (address => mapping (address => uint)) allowed_S_coupons;


    uint B_coupon_allocation_factor = 50;
    
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

    event ApprovalScoupons(address indexed owner, address indexed receiver, uint value);


    /* 
    * Create coupons for given number of FedCoup tokens. 
    *         _numberOfTokens : given FedCoup token (1 FedCoup token equal to 1 ether with respect to number format)
    */
    function createCoupons(uint _numberOfTokens) onlyPayloadSize(2 * 32) external {

        /* 
        * subtract given token from sender token balance 
        */
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

        /* 
        * log event 
        */
        CouponsCreated(msg.sender, newBcoupons, newScoupons);
    }


    /*
    * accept B coupons.
    *
    * Parameters:
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
    *
    * Parameters:
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

        /*
        * approve B coupons from message sender to acceptor.
        */
        allowed_B_coupons[msg.sender][_acceptor] = _Bcoupons;

        /*
        * log event.
        */ 
        ApprovalBcoupons(msg.sender, _acceptor, _Bcoupons);
    }    

    /*
    * Approve S coupons
    * 
    * Parameters:
    *       _receiver: address of the receiver.
    *       _Scoupons: number of S coupons has to be allowed to receiver.
    */
    function approveScoupons(address _receiver, uint _Scoupons) external {

        /*
        * approve S coupons from message sender to receiver.
        */
        allowed_S_coupons[msg.sender][_receiver] = _Scoupons;

        /*
        * log event.
        */ 
        ApprovalScoupons(msg.sender, _receiver, _Scoupons);
    }    

    /*
    * Get allowed B coupons from address to acceptor address.
    *
    * Parameters:
    *       _from: address of the B coupon sender.
    *       _acceptor: address of the B coupon acceptor.
    */
    function allowanceBcoupons(address _from, address _acceptor) constant external returns (uint remaining) {
        return allowed_B_coupons[_from][_acceptor];
    }

    /*
    * Get coupon multiplication factor.
    */
    function getCouponMulFactor() constant external returns (uint) {
        return coupon_mul_factor; 
    }    

    /*
    * Set coupon multiplication factor.
    *
    * Parameters:
    *       couponMulFactor: The number of coupons for 1 Federation token.
    */
    function setCouponMulFactor(uint couponMulFactor) external onlyOwner {
        coupon_mul_factor = couponMulFactor; 
    } 

    /*
    * Get Federation token balance for given address.
    * 
    * Parameters:
    *       _addr: The address for which the token balance has to be retrieved.
    */
    function getTokenBalances(address _addr) constant external returns (uint) {
        return balances[ _addr ]; 
    }

    /*
    * Get B coupon allocation factor which indicates the percentage of 
    * how many B coupons will be allocated to the user for given Federation token. 
    */
    function getBcouponAllocationFactor() constant external returns (uint) {
        return B_coupon_allocation_factor;
    } 

    /*
    * Set B coupon allocation factor.
    *
    * Parameters:
    *       BcouponAllocFactor: The B coupon allocation factor in percentage.
    */
    function setBcouponAllocationFactor(uint BcouponAllocFactor) external onlyOwner {
        B_coupon_allocation_factor = BcouponAllocFactor;
    } 

    /*
    * Get S coupon allocation factor which indicates the percentage of 
    * how many S coupons will be allocated to the user for given Federation token.
    */
    function getScouponAllocationFactor() constant external returns (uint) {
        return S_coupon_allocation_factor;
    }

    /*
    * Set S coupon allocation factor.
    *
    * Parameters:
    *       ScouponAllocFactor: The S coupon allocation factor in percentage.
    */
    function setScouponAllocationFactor(uint ScouponAllocFactor) external onlyOwner {
        S_coupon_allocation_factor = ScouponAllocFactor;
    }

    /*
    * Get B coupon transfer cost. 
    */
    function getBcouponTransferCost() constant external returns (uint) {
        return transferCostBcoupon;
    }

    /*
    * Set B coupon transfer cost.
    *
    * Parameters:
    *       transferCostBcoup: The number B coupons deducted as cost for transfering them.
    */
    function setBcouponTransferCost(uint transferCostBcoup) external onlyOwner {
        transferCostBcoupon = transferCostBcoup;
    }    

    /*
    * Get S coupon transfer cost.
    */
    function getScouponTransferCost() constant external returns (uint) {
        return transferCostScoupon;
    }     

    /*
    * Set S coupon transfer cost.
    */
    function setScouponTransferCost(uint transferCostScoup) external onlyOwner {
        transferCostScoupon = transferCostScoup;
    }

    /*
    * Get B coupon balance.
    */
    function getBcouponBalances(address _addr) constant external returns (uint) {
        return balance_B_coupons[ _addr ];
    }

    /*
    * Get S coupon balance.
    */
    function getScouponBalances(address _addr) constant external returns (uint) {
        return balance_S_coupons[ _addr ];
    }   

    /*
    * Get balance of residual B coupons.
    */
    function getBalanceOfResidualBcoupons() constant external returns (uint) {
        return residualBcoupons;
    }


    /*************************************************************************************************/
    /* Contractors functions
    /* ---------------------
    /*      The contractor functions designed to support future contractor contracts.
    /* These contractors might be out of the blockchain or out of the ethereum blockchain etc.
    /* The contractors should follow the FedCoup principle wherever they are implemented. The below
    /* list functions are the minimal set of functions which directly updates the coupons 
    /* and tokens for the user. The contractor criteria will be established as a seperate contract. 
    /**************************************************************************************************/

    address public contractorImpl;

    event ContractorTransferBcoupons(address indexed sender, address indexed receiver, uint numberOfBcoupons);

    event ContractorTransferScoupons(address indexed sender, address indexed receiver, uint numberOfScoupons);


    modifier onlyContractorImpl() {
        if (msg.sender == contractorImpl) {
            throw;
        }
        _;
    }

    function setContractorImpl(address _contractorImplAddr) onlyPayloadSize(2 * 32) onlyOwner {
        contractorImpl = _contractorImplAddr;
    }

    function contractorTransfer_Bcoupon(address _to, uint _numberOfBcoupons) onlyPayloadSize(2 * 32) onlyContractorImpl external {
        balance_B_coupons[msg.sender] = balance_B_coupons[msg.sender].sub(_numberOfBcoupons);
        balance_B_coupons[_to] = balance_B_coupons[_to].add(_numberOfBcoupons);

        /*
        * log event.
        */
        ContractorTransferBcoupons(msg.sender, _to, _numberOfBcoupons);
    }

    function contractorTransferFrom_Bcoupon(address _from, address _to, uint _numberOfBcoupons) onlyPayloadSize(2 * 32) onlyContractorImpl external {
        /*
        * The B coupons which has to be allowed _from address to _to address.
        */
        var _allowance = allowed_B_coupons[_from][msg.sender];

        /* 
        * substract B coupons from _from account.
        */
        balance_B_coupons[ _from ] = balance_B_coupons[ _from ].sub( _numberOfBcoupons );

        /*
        * substract allowed_B_coupons for transfered _numberOfBcoupons.
        */
        allowed_B_coupons[_from][msg.sender] = _allowance.sub(_numberOfBcoupons);

        /* 
        * log event. 
        */
        ContractorTransferBcoupons(_from, _to, _numberOfBcoupons);

    }

    function contractorTransfer_Scoupon(address _to, uint _numberOfScoupons) onlyPayloadSize(2 * 32) onlyContractorImpl external {
        balance_S_coupons[msg.sender] = balance_S_coupons[msg.sender].sub(_numberOfScoupons);
        balance_S_coupons[_to] = balance_S_coupons[_to].add(_numberOfScoupons);

        /*
        * log event.
        */
        ContractorTransferScoupons(msg.sender, _to, _numberOfScoupons);
    }

    function contractorTransferFrom_Scoupon(address _from, address _to, uint _numberOfScoupons) onlyPayloadSize(2 * 32) onlyContractorImpl external {
        /*
        * The S coupons which has to be allowed _from address to _to address.
        */
        var _allowance = allowed_S_coupons[_from][msg.sender];

        /* 
        * substract S coupons from _from account.
        */
        balance_S_coupons[ _from ] = balance_S_coupons[ _from ].sub( _numberOfScoupons );

        /*
        * substract allowed_S_coupons for transfered _numberOfScoupons.
        */
        allowed_S_coupons[_from][msg.sender] = _allowance.sub(_numberOfScoupons);

        /* 
        * log event. 
        */
        ContractorTransferScoupons(_from, _to, _numberOfScoupons);
    }    
}