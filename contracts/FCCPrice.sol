pragma solidity ^0.4.4;

/*
* FCC (FedCoup currency) price in USD.
*/
contract FCCPrice {

    uint public FCC_price = 10 finney; 

    /*
    * Get FCC price in USD.
    */
    function getFCCPrice() constant returns (uint);
}