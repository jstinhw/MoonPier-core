// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/console2.sol";
import {WETHGateway} from "../../contracts/core/WETHGateway.sol";
import {WETH9Mocked} from "../../contracts/mocks/WETH9Mocked.sol";
import {DataTypes} from "../../contracts/libraries/DataTypes.sol";
import {BaseSetup} from "./BaseSetup.t.sol";
import {Errors} from "../../contracts/libraries/Errors.sol";

contract LeaveTest is BaseSetup {
  uint256 public downpaymentWETH = 1000;

  function setUp() public virtual override {
    BaseSetup.setUp();
    moonfishproxy.addReserve(address(weth), address(mtoken));
    wethgateway = new WETHGateway(address(weth), address(moonfishproxy));
  }

  function testleaveETHBeforeCollectionCreated() public {
    // join with id 1 and 10 eth
    uint256 id = 0x3e8;
    uint256 amount = 10 ether;
    uint256 mTokenAmount = (amount * (10000 - downpaymentWETH)) / 10000;

    vm.startPrank(alice);
    wethgateway.joinETH{value: amount}(id);

    // leave before creator create collection
    mtoken.setApprovalForAll(address(wethgateway), true);
    uint256 ethBefore = address(alice).balance;
    wethgateway.leaveETH(id, mTokenAmount, alice);
    uint256 ethAfter = address(alice).balance;

    assertEq(ethAfter - ethBefore, amount);
    assertEq(mtoken.balanceOf(alice, id), 0);
    assertEq(mtoken.balanceOf(address(mtoken), id), 0);
  }

  function testleaveETHBeforeCollectionCreatedFuzz(uint256 amount) public {
    vm.assume(amount > 1 ether && amount < 100 ether);
    // join with id 1 and 10 eth
    uint256 id = 0x3e8;
    uint256 mTokenAmount = (amount * (10000 - downpaymentWETH)) / 10000;

    vm.startPrank(alice);
    wethgateway.joinETH{value: amount}(id);

    // leave before creator create collection
    mtoken.setApprovalForAll(address(wethgateway), true);
    uint256 ethBefore = address(alice).balance;
    wethgateway.leaveETH(id, mTokenAmount, alice);
    uint256 ethAfter = address(alice).balance;

    assertEq(amount - (ethAfter - ethBefore) < downpaymentWETH, true);
    assertEq(mtoken.balanceOf(alice, id), 0);
    // assertEq(mtoken.balanceOf(address(mtoken), id), 0);
  }

  function testleaveETHAfterCollectionCreated() public {
    // join with id 1 and 10 eth
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x3E8;
    uint256 amount = 10 ether;
    uint256 mTokenAmount = (amount * (10000 - downpaymentWETH)) / 10000;
    uint256 downpayment = amount - mTokenAmount;

    vm.prank(alice);
    wethgateway.joinETH{value: amount}(id);

    // creator create collection
    string memory name = "name";
    string memory symbol = "NM";
    DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
      fundsReceiver: creator,
      maxSupply: 100,
      maxAmountPerAddress: 1,
      publicMintPrice: 3 ether,
      publicStartTime: block.timestamp,
      publicEndTime: block.timestamp + 1000,
      whitelistStartTime: block.timestamp,
      whitelistEndTime: block.timestamp + 1000,
      presaleMaxSupply: 10,
      presalePrice: 1 ether,
      presaleAmountPerWallet: 1,
      presaleStartTime: block.timestamp,
      presaleEndTime: block.timestamp + 1000
    });
    vm.prank(creator);
    moonfishproxy.createCollection(address(weth), id, name, symbol, config);

    // leave before creator create collection
    vm.startPrank(alice);
    mtoken.setApprovalForAll(address(wethgateway), true);
    uint256 ethBefore = address(alice).balance;
    wethgateway.leaveETH(id, mTokenAmount, alice);
    uint256 ethAfter = address(alice).balance;

    assertEq(ethAfter - ethBefore, mTokenAmount);
    assertEq(mtoken.balanceOf(alice, id), 0);
    assertEq(mtoken.balanceOf(creator, id), downpayment);
  }

  function testCannotLeaveWithZeroAmount() public {
    uint256 id = 0x3e8;
    uint256 amount = 0 ether;
    uint256 mTokenAmount = (amount * (10000 - downpaymentWETH)) / 10000;

    vm.startPrank(alice);
    mtoken.setApprovalForAll(address(wethgateway), true);
    vm.expectRevert("Leave: amount cannot be zero");
    wethgateway.leaveETH(id, mTokenAmount, alice);
  }

  function testCannotLeaveBeforeJoin() public {
    uint256 id = 0x3e8;
    uint256 amount = 1 ether;
    uint256 downpayment = (amount * downpaymentWETH) / 10000;
    uint256 mTokenAmount = amount - downpayment;
    // uint256 premintedAmount = amount * (100 - downpaymentWETH) / 100;

    vm.startPrank(alice);
    mtoken.setApprovalForAll(address(wethgateway), true);
    vm.expectRevert(Errors.GatewayLeaveInsufficientBalance.selector);
    wethgateway.leaveETH(id, mTokenAmount, alice);
  }

  function testCannotLeaveInvalidAmount() public {
    uint256 id = 0x3e8;
    uint256 amount = 1 ether;
    uint256 mTokenAmount = (amount * (10000 - downpaymentWETH)) / 10000;

    vm.startPrank(alice);
    wethgateway.joinETH{value: amount}(id);
    mtoken.setApprovalForAll(address(wethgateway), true);
    vm.expectRevert(Errors.GatewayLeaveInsufficientBalance.selector);
    wethgateway.leaveETH(id, mTokenAmount + 10, alice);
  }

  function testCannotLeaveByOther() public {
    uint256 id = 0x3e8;
    uint256 amount = 0 ether;
    uint256 downpayment = (amount * downpaymentWETH) / 10000;
    uint256 mTokenAmount = amount - downpayment;

    vm.startPrank(alice);
    wethgateway.joinETH{value: amount}(id);
    vm.stopPrank();

    vm.prank(bob);
    mtoken.setApprovalForAll(address(moonfishproxy), true);
    vm.expectRevert("Leave: amount cannot be zero");
    moonfishproxy.leave(address(weth), id, mTokenAmount, alice);
  }
}
