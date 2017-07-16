pragma solidity ^0.4.4;

import "./FCCPrice.sol";

/*
* FCC (FedCoup currency) price in USD.
*/
contract FCCPriceDefault is FCCPrice {

	function FCCPriceDefault(uint defaultFCCPrice) {
		FCC_price = defaultFCCPrice;
	}

    /*
    * Get FCC price in USD.
    */
    function getFCCPrice() constant returns (uint) {
    	return FCC_price;
    }
}