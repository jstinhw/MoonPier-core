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
    moonpierproxy.addReserve(address(weth), address(mtoken));
    wethgateway = new WETHGateway(address(weth), address(moonpierproxy));
    vm.stopPrank();
  }

  function testGetReserveCount() public {
    assertEq(moonpierproxy.getReserveCount(), 1);
  }

  function testGetReserveUnderlying() public {
    assertEq(moonpierproxy.getReserveUnderlyingFromId(0), address(weth));
  }

  function testUpdateImpl() public {
    vm.startPrank(admin);
    moonpierproxy.upgradeTo(moonpierproxy.erc721implementation());
  }

  function testCannotUpdateImplNotAdmin() public {
    vm.startPrank(creator);
    address newImp = moonpierproxy.erc721implementation();
    vm.expectRevert("Ownable: caller is not the owner");
    moonpierproxy.upgradeTo(newImp);
  }
}
