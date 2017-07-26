pragma solidity ^0.4.4;

import "./CouponCostFunction.sol";
import "zeppelin/ownership/Ownable.sol";

/*
* Default transfer cost functions to set cost values. 
*/
contract CouponCostFunctionDefault is CouponCostFunction, Ownable {

	function CouponCostFunctionDefault(uint _transferCostBcoupon, uint _transferCostScoupon) onlyOwner {
		transferCostBcoupon = _transferCostBcoupon;
		transferCostScoupon = _transferCostScoupon;
	}

	/*
	* 
	*/
	function setBcouponTransferCost(uint cost) onlyOwner {
		transferCostBcoupon = cost; 
	}

	/*
	*
	*/
	function setScouponTransferCost(uint cost) onlyOwner {
		transferCostScoupon = cost;
	}

	/*
    * 
    */
    function getBcouponTransferCost() constant returns (uint) {
    	return transferCostBcoupon;
    }

    /*
    *
    */
    function getScouponTransferCost() constant returns (uint) {
    	return transferCostScoupon;
    }

}