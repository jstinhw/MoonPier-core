// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {BaseSetup} from "./BaseSetup.t.sol";
import {WETHGateway} from "../../contracts/core/WETHGateway.sol";
import {IMToken} from "../../contracts/interfaces/IMToken.sol";
import {IERC165Upgradeable} from "openzeppelin-upgradeable/contracts/interfaces/IERC165Upgradeable.sol";
import {IERC1155Receiver} from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155Receiver.sol";
import {IERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";

contract MTokenTest is BaseSetup {
  uint256 public downpaymentWETH = 1000;

  function setUp() public virtual override {
    BaseSetup.setUp();
    vm.startPrank(admin);
    moonfishproxy.addReserve(address(weth), address(mtoken));
    wethgateway = new WETHGateway(address(weth), address(moonfishproxy));
    vm.stopPrank();
  }

  function testCannotMint() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 14) | 0x3E8;

    vm.startPrank(alice);
    IMToken mToken = IMToken(moonfishproxy.getReserveData(address(weth)).mToken);
    vm.expectRevert("MToken: not from moonfish");
    mToken.mint(alice, id, 1);
  }

  function testCannotMintFromCreator() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 14) | 0x3E8;

    vm.startPrank(creator);
    IMToken mToken = IMToken(moonfishproxy.getReserveData(address(weth)).mToken);
    vm.expectRevert("MToken: not from moonfish");
    mToken.mint(creator, id, 1);
  }

  function testCannotBurn() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 14) | 0x3E8;

    vm.startPrank(creator);
    IMToken mToken = IMToken(moonfishproxy.getReserveData(address(weth)).mToken);
    vm.expectRevert("MToken: not from moonfish");
    mToken.burn(creator, id, 1);
  }

  function testTransfer() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 14) | 0x3E8;
    uint256 amount = 10 ether;
    uint256 mTokenAmount = (amount * (10000 - downpaymentWETH)) / 10000;

    vm.startPrank(alice);
    wethgateway.joinETH{value: amount}(id);
    IMToken mToken = IMToken(moonfishproxy.getReserveData(address(weth)).mToken);
    mToken.safeTransferFrom(alice, bob, id, 1 ether, "");
    assertEq(mToken.balanceOf(alice, id), mTokenAmount - 1 ether);
    assertEq(mToken.balanceOf(bob, id), 1 ether);
  }

  function testCannotTransferTokenNotOwner() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 14) | 0x3E8;
    uint256 amount = 10 ether;

    vm.prank(alice);
    wethgateway.joinETH{value: amount}(id);
    IMToken mToken = IMToken(moonfishproxy.getReserveData(address(weth)).mToken);

    vm.expectRevert("ERC1155: caller is not token owner or approved");
    vm.prank(bob);
    mToken.safeTransferFrom(alice, bob, id, 1 ether, "");
  }

  function testgetUnderlying() public {
    IMToken mToken = IMToken(moonfishproxy.getReserveData(address(weth)).mToken);
    assertEq(mToken.getUnderlyingAsset(), address(weth));
  }

  function testgetSupportsInterface() public {
    IMToken mToken = IMToken(moonfishproxy.getReserveData(address(weth)).mToken);
    assertTrue(mToken.supportsInterface(type(IERC165Upgradeable).interfaceId));
    assertTrue(mToken.supportsInterface(type(IERC1155).interfaceId));
    assertTrue(mToken.supportsInterface(type(IERC1155Receiver).interfaceId));
  }
}
