// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Test} from "forge-std/Test.sol";
import {BaseSetup} from "./BaseSetup.t.sol";
import {WETHGateway} from "../../contracts/core/WETHGateway.sol";
import {TokenIdentifiers} from "../../contracts/core/TokenIdentifiers.sol";

contract TestTokenIdentifier is BaseSetup {
  using TokenIdentifiers for uint256;

  function setUp() public virtual override {
    BaseSetup.setUp();
    vm.startPrank(admin);
    moonfishproxy.addReserve(address(weth), address(mtoken));
    wethgateway = new WETHGateway(address(weth), address(moonfishproxy));
    vm.stopPrank();
  }

  function testTokenIdentifier() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x3E8;

    assertEq(TokenIdentifiers.tokenDownpayment(id), 1000);
    assertEq(TokenIdentifiers.tokenIndex(id), 0);
    assertEq(TokenIdentifiers.tokenCreator(id), creator);
  }
}
