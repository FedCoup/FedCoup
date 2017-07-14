pragma solidity ^0.4.2;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/FedCoup.sol";

contract TestFedCoup {

  function testTransferResidualBcoupons() {
    /* test initial condition */
    FedCoup fcoup = FedCoup(DeployedAddresses.FedCoup());

    uint expected = 0;

    Assert.equal(fcoup.getBalanceOfResidualBcoupons(), expected, "Expected initial residual coupons is 0");
  }


}
