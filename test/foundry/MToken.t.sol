// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {BaseSetup} from "./BaseSetup.t.sol";
import {WETHGateway} from "../../contracts/core/WETHGateway.sol";
import {IMToken} from "../../contracts/interfaces/IMToken.sol";

contract MTokenTest is BaseSetup {
  uint256 public downpaymentWETH = 10;

  function setUp() public virtual override {
    BaseSetup.setUp();
    moonfishproxy.addReserve(address(weth), downpaymentWETH, address(mtoken));
    wethgateway = new WETHGateway(address(weth), address(moonfishproxy));
  }

  function testCannotMint() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x01;

    vm.startPrank(alice);
    IMToken mToken = IMToken(moonfishproxy.getReserveData(address(weth)).mToken);
    vm.expectRevert("MToken: not from moonfish");
    mToken.mint(alice, id, 1);
  }

  function testCannotMintFromCreator() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x01;

    vm.startPrank(creator);
    IMToken mToken = IMToken(moonfishproxy.getReserveData(address(weth)).mToken);
    vm.expectRevert("MToken: not from moonfish");
    mToken.mint(creator, id, 1);
  }

  function testCannotBurn() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x01;

    vm.startPrank(creator);
    IMToken mToken = IMToken(moonfishproxy.getReserveData(address(weth)).mToken);
    vm.expectRevert("MToken: not from moonfish");
    mToken.burn(creator, id, 1);
  }

  function testTransfer() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x01;
    uint256 amount = 10 ether;
    uint256 mTokenAmount = (amount * (100 - downpaymentWETH)) / 100;

    vm.startPrank(alice);
    wethgateway.joinETH{value: amount}(id);
    IMToken mToken = IMToken(moonfishproxy.getReserveData(address(weth)).mToken);
    mToken.safeTransferFrom(alice, bob, id, 1 ether, "");
    assertEq(mToken.balanceOf(alice, id), mTokenAmount - 1 ether);
    assertEq(mToken.balanceOf(bob, id), 1 ether);
  }
}
