pragma solidity ^0.4.4;

/*
* FCC (FedCoup token) price in USD.
*/
contract FCCPrice {

    uint public FCC_price; 

    /*
    * Get FCC price in USD.
    */
    function getFCCPrice() constant returns (uint);
}