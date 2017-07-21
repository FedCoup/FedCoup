pragma solidity ^0.4.4;

import "./CouponCostFunction.sol";
import "zeppelin/ownership/Ownable.sol";

/*
* Default transfer cost functions to set cost values. 
*/
contract CouponCostFunctionDefault is CouponCostFunction, Ownable {

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
}