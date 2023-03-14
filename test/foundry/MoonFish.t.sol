// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import {BaseSetup} from "./BaseSetup.t.sol";
import {WETHGateway} from "../../contracts/core/WETHGateway.sol";
import {Errors} from "../../contracts/libraries/Errors.sol";

contract TestWETHGateway is BaseSetup {
  uint256 public downpaymentWETH = 1000;

  function setUp() public override {
    BaseSetup.setUp();
    vm.startPrank(admin);
    moonfishproxy.addReserve(address(weth), address(mtoken));
    wethgateway = new WETHGateway(address(weth), address(moonfishproxy));
    vm.stopPrank();
  }

  function testGetReserveCount() public {
    assertEq(moonfishproxy.getReserveCount(), 1);
  }

  function testGetReserveUnderlying() public {
    assertEq(moonfishproxy.getReserveUnderlyingFromId(0), address(weth));
  }

  function testUpdateImpl() public {
    vm.startPrank(admin);
    moonfishproxy.upgradeTo(moonfishproxy.erc721implementation());
  }

  function testCannotUpdateImplNotAdmin() public {
    vm.startPrank(creator);
    address newImp = moonfishproxy.erc721implementation();
    vm.expectRevert("Ownable: caller is not the owner");
    moonfishproxy.upgradeTo(newImp);
  }
}
