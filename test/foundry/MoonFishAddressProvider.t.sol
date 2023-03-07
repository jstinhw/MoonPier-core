// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import {BaseSetup} from "./BaseSetup.t.sol";
import {WETHGateway} from "../../contracts/core/WETHGateway.sol";
import "forge-std/console2.sol";
import {Errors} from "../../contracts/libraries/Errors.sol";

contract TestMoonFishAddressProvider is BaseSetup {
  uint256 public downpaymentWETH = 1000;

  function setUp() public override {
    BaseSetup.setUp();
    vm.startPrank(admin);
    moonfishproxy.addReserve(address(weth), address(mtoken));
    wethgateway = new WETHGateway(address(weth), address(moonfishproxy));
    vm.stopPrank();
  }

  function testUpgradeImplementation() public {
    vm.startPrank(admin);
    moonFishAddressProviderProxy.upgradeTo(moonfishproxy.erc721implementation());
  }

  function testCannotUpgradeImplementationNotAdmin() public {
    address newImp = address(moonfishproxy.erc721implementation());
    vm.expectRevert("Ownable: caller is not the owner");
    vm.startPrank(creator);
    moonFishAddressProviderProxy.upgradeTo(newImp);
  }

  function testCannotUpgradeImplementationNotContract() public {
    vm.expectRevert();
    vm.startPrank(admin);
    moonFishAddressProviderProxy.upgradeTo(admin);
  }

  function testSetUp() public {
    BaseSetup.setUp();
  }

  function testSetMoonFish() public {
    vm.startPrank(admin);
    moonFishAddressProviderProxy.setMoonFish(address(alice));
    assertEq(moonFishAddressProviderProxy.getMoonFish(), address(alice));
  }

  function testSetFeeManager() public {
    vm.startPrank(admin);
    moonFishAddressProviderProxy.setFeeManager(address(alice));
    assertEq(moonFishAddressProviderProxy.getFeeManager(), address(alice));
  }

  function testCannotSetMoonFishNotAdmin() public {
    vm.expectRevert("Ownable: caller is not the owner");
    vm.startPrank(alice);
    moonFishAddressProviderProxy.setMoonFish(address(alice));
  }

  function testCannotSetFeeManagerNotAdmin() public {
    vm.expectRevert("Ownable: caller is not the owner");
    vm.startPrank(alice);
    moonFishAddressProviderProxy.setFeeManager(address(alice));
  }
}
