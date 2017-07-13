pragma solidity ^0.4.4;
import "zeppelin/token/MintableToken.sol";


contract FedCoupDuplicate is MintableToken {

    /* Public variables of the token */
    string public standard = 'Token 0.1';
    
    //currency name
    string public name;
    
    //currency symbol
    string public symbol;
    
    //?
    uint8 public decimals;
    
    //total currency supply
    uint256 public totalSupply;

    //balance of FedCoup coin for each address
    mapping (address => uint256) public balanceOf;
    
    //balance of S token for each address
    mapping (address => uint256) public balanceOfStoken;
    
    //balance of B token for each address
    mapping (address => uint256) public balanceOfBtoken;
    
    
    //?
    // mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);

    event TransferBtoken(address indexed from, uint256 value);
    
    /* Initializes contract with initial supply tokens to the creator of the contract */
    function FedCoup (
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
        ) {
        // Give the creator all initial tokens
        balanceOf[msg.sender] = initialSupply;
        
        // Update total supply
        totalSupply = initialSupply;
        
        // Set the name for display purposes
        name = tokenName;                   
        
        // Set the symbol for display purposes
        symbol = tokenSymbol;                 
        
        // Amount of decimals for display purposes
        decimals = decimalUnits;                            
    }

    //transfer coins to TO address
    function transfer(address _to, uint256 _value) {
        // Prevent transfer to 0x0 address. Use burn() instead
        if (_to == 0x0) throw;                               
        
        // Check if the sender has enough
        if (balanceOf[msg.sender] < _value) throw;           
        
        // Check for overflows
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;
        
        // Subtract from the sender
        balanceOf[msg.sender] -= _value;                     
        
        // Add the same to the recipient
        balanceOf[_to] += _value;                            
        
        // Notify anyone listening that this transfer took place
        Transfer(msg.sender, _to, _value);                   
    }

    /* Allow another contract to spend some tokens in your behalf */
    // function approve(address _spender, uint256 _value)
    //     returns (bool success) {
    //     allowance[msg.sender][_spender] = _value;
    //     return true;
    // }

    /* Approve and then communicate the approved contract in a single tx */
    // function approveAndCall(address _spender, uint256 _value, bytes _extraData)
    //     returns (bool success) {
    //     tokenRecipient spender = tokenRecipient(_spender);
    //     if (approve(_spender, _value)) {
    //         spender.receiveApproval(msg.sender, _value, this, _extraData);
    //         return true;
    //     }
    // }        

    //?
    /* A contract attempts to get the coins */
    // function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
    //     if (_to == 0x0) throw;                                // Prevent transfer to 0x0 address. Use burn() instead
    //     if (balanceOf[_from] < _value) throw;                 // Check if the sender has enough
    //     if (balanceOf[_to] + _value < balanceOf[_to]) throw;  // Check for overflows
    //     if (_value > allowance[_from][msg.sender]) throw;     // Check allowance
    //     balanceOf[_from] -= _value;                           // Subtract from the sender
    //     balanceOf[_to] += _value;                             // Add the same to the recipient
    //     allowance[_from][msg.sender] -= _value;
    //     Transfer(_from, _to, _value);
    //     return true;
    // }

    function burn(uint256 _value) returns (bool success) {
        // Check if the sender has enough
        if (balanceOf[msg.sender] < _value) throw;
        
        // Subtract from the sender
        balanceOf[msg.sender] -= _value;
        
        // Updates totalSupply
        totalSupply -= _value;
        
        //record event
        Burn(msg.sender, _value);
        
        return true;
    }

    // function burnFrom(address _from, uint256 _value) returns (bool success) {
    //     if (balanceOf[_from] < _value) throw;                // Check if the sender has enough
    //     if (_value > allowance[_from][msg.sender]) throw;    // Check allowance
    //     balanceOf[_from] -= _value;                          // Subtract from the sender
    //     totalSupply -= _value;                               // Updates totalSupply
    //     Burn(_from, _value);
    //     return true;
    // }
    
    //create tokens using FC
    function createTokens(address _from, uint256 _FC) returns (bool success) {
        //check if enough balance in from address
        if (balanceOf[_from] < _FC) throw;
        
        //substract balance 
        balanceOf[_from] -= _FC;
        
        //overflow check
        if (balanceOfStoken[_from] + _FC * 1 ether  < _FC * 1 ether) throw;
        
        //create s tokens
        balanceOfStoken[_from] += _FC * 1 ether;
        
         //overflow check
        if (balanceOfBtoken[_from] + _FC * 1 ether  < _FC * 1 ether) throw;
        
        //create b tokens
        balanceOfBtoken[_from] += _FC * 1 ether;

        return true;
    }

    function accept(address _from, uint256 _bTokens) returns (bool success) {
        //check if enough B tokens in the buckets
        if (balanceOfStoken[_from] < _bTokens) throw;
        
        //substract S balance
        balanceOfStoken[_from] -= _bTokens;
    
        //add it to FC balance
        balanceOf[msg.sender] += _bTokens;
        
        //trigger event
        TransferBtoken(msg.sender, _bTokens);
        
        return true;
    }

}