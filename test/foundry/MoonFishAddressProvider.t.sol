// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import {BaseSetup} from "./BaseSetup.t.sol";
import {WETHGateway} from "../../contracts/core/WETHGateway.sol";
import {Errors} from "../../contracts/libraries/Errors.sol";

contract TestMoonPierAddressProvider is BaseSetup {
  uint256 public downpaymentWETH = 1000;

  function setUp() public override {
    BaseSetup.setUp();
    vm.startPrank(admin);
    moonpierproxy.addReserve(address(weth), address(mtoken));
    wethgateway = new WETHGateway(address(weth), address(moonpierproxy));
    vm.stopPrank();
  }

  function testUpgradeImplementation() public {
    vm.startPrank(admin);
    moonPierAddressProviderProxy.upgradeTo(moonpierproxy.erc721implementation());
  }

  function testCannotUpgradeImplementationNotAdmin() public {
    address newImp = address(moonpierproxy.erc721implementation());
    vm.expectRevert("Ownable: caller is not the owner");
    vm.startPrank(creator);
    moonPierAddressProviderProxy.upgradeTo(newImp);
  }

  function testCannotUpgradeImplementationNotContract() public {
    vm.expectRevert();
    vm.startPrank(admin);
    moonPierAddressProviderProxy.upgradeTo(admin);
  }

  function testSetUp() public {
    BaseSetup.setUp();
  }

  function testSetMoonPier() public {
    vm.startPrank(admin);
    moonPierAddressProviderProxy.setMoonPier(address(alice));
    assertEq(moonPierAddressProviderProxy.getMoonPier(), address(alice));
  }

  function testSetFeeManager() public {
    vm.startPrank(admin);
    moonPierAddressProviderProxy.setFeeManager(address(alice));
    assertEq(moonPierAddressProviderProxy.getFeeManager(), address(alice));
  }

  function testCannotSetMoonPierNotAdmin() public {
    vm.expectRevert("Ownable: caller is not the owner");
    vm.startPrank(alice);
    moonPierAddressProviderProxy.setMoonPier(address(alice));
  }

  function testCannotSetFeeManagerNotAdmin() public {
    vm.expectRevert("Ownable: caller is not the owner");
    vm.startPrank(alice);
    moonPierAddressProviderProxy.setFeeManager(address(alice));
  }
}
