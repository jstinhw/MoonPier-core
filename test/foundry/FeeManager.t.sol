// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import {BaseSetup} from "./BaseSetup.t.sol";
import {WETHGateway} from "../../contracts/core/WETHGateway.sol";
import "forge-std/console2.sol";

contract TestFeeManager is BaseSetup {
  uint256 public downpaymentWETH = 1000;

  function setUp() public override {
    BaseSetup.setUp();
    vm.startPrank(admin);
    moonfishproxy.addReserve(address(weth), address(mtoken));
    wethgateway = new WETHGateway(address(weth), address(moonfishproxy));
    vm.stopPrank();
  }

  function testSetFeeFuzz(uint256 amount) public {
    vm.assume(amount > 0 && amount < 2000);
    vm.startPrank(admin);
    feeManager.setFeeOverride(address(wethgateway), amount);
    (address payable feeRecipient, uint256 fee) = feeManager.getFees(address(wethgateway));
    assertEq(feeRecipient, admin);
    assertEq(fee, amount);
  }

  function testCannotSetFeeNotAdmin() public {
    uint256 amount = 1000;
    vm.startPrank(creator);
    vm.expectRevert("Ownable: caller is not the owner");
    feeManager.setFeeOverride(address(wethgateway), amount);
  }

  function testCannotSetFeeExceedMax() public {
    uint256 amount = 2001;
    vm.startPrank(admin);
    vm.expectRevert("FeeManager: Fee can only be set in 0 - 20%");
    feeManager.setFeeOverride(address(wethgateway), amount);
  }
}
