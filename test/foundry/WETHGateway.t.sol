// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import {BaseSetup} from "./BaseSetup.t.sol";
import {WETHGateway} from "../../contracts/core/WETHGateway.sol";
import {Errors} from "../../contracts/libraries/Errors.sol";
import {IERC1155Receiver} from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155Receiver.sol";
import {IERC165} from "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";

contract TestWETHGateway is BaseSetup {
  uint256 public downpaymentWETH = 1000;

  function setUp() public override {
    BaseSetup.setUp();
    vm.startPrank(admin);
    moonpierproxy.addReserve(address(weth), address(mtoken));
    wethgateway = new WETHGateway(address(weth), address(moonpierproxy));
    vm.stopPrank();
  }

  function testgetSupportsInterface() public {
    assertTrue(wethgateway.supportsInterface(type(IERC165).interfaceId));
    assertTrue(wethgateway.supportsInterface(type(IERC1155Receiver).interfaceId));
  }

  function testCannotFallBack() public {
    (bool success, ) = address(wethgateway).call("0x01020304");
    assertFalse(success);
  }
}
