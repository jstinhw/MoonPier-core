// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {WETHGateway} from "../../contracts/core/WETHGateway.sol";
import {WETH9Mocked} from "../../contracts/mocks/WETH9Mocked.sol";
import {DataTypes} from "../../contracts/libraries/DataTypes.sol";
import {BaseSetup} from "./BaseSetup.t.sol";

contract JoinTest is BaseSetup {
  uint256 public downpaymentWETH = 1000;

  function setUp() public virtual override {
    BaseSetup.setUp();
    vm.startPrank(admin);
    moonpierproxy.addReserve(address(weth), address(mtoken));
    wethgateway = new WETHGateway(address(weth), address(moonpierproxy));
    vm.stopPrank();
  }

  function testjoinETH() public {
    uint256 id = 0x3e8;
    uint256 amount = 10 ether;
    uint256 mTokenAmount = (amount * (10000 - downpaymentWETH)) / 10000;

    // join with id 1 and 10 eth
    vm.prank(alice);
    wethgateway.joinETH{value: amount}(id);
    assertEq(weth.balanceOf(address(mtoken)), amount);
    assertEq(mtoken.balanceOf(alice, id), mTokenAmount);
  }

  function testjoinETHFuzz(uint96 amount) public {
    vm.assume(amount > 0 && amount < 100 ether);
    uint256 id = 0x3e8;
    uint256 mTokenAmount = (amount * (10000 - downpaymentWETH)) / 10000;

    // join with id 1 and amount eth
    vm.prank(alice);
    wethgateway.joinETH{value: amount}(id);
    assertEq(weth.balanceOf(address(mtoken)), amount);
    assertEq(mtoken.balanceOf(alice, id), mTokenAmount);
  }

  function testJoinETHThroughMoonPier() public {
    uint256 id = 0x3e8;
    uint256 amount = 10 ether;
    uint256 mTokenAmount = (amount * (10000 - downpaymentWETH)) / 10000;

    // join with id 1 and 10 eth
    vm.startPrank(alice);
    WETH9Mocked(payable(address(weth))).deposit{value: amount}();
    WETH9Mocked(payable(address(weth))).transferFrom(alice, address(moonpierproxy), amount);
    moonpierproxy.join(address(weth), id, amount, alice);
    assertEq(weth.balanceOf(address(mtoken)), amount);
    assertEq(mtoken.balanceOf(alice, id), mTokenAmount);
  }

  function testjoinETHWithZeroAmount() public {
    uint256 id = 0x3e8;
    uint256 amount = 0 ether;
    uint256 mTokenAmount = (amount * (10000 - downpaymentWETH)) / 10000;

    // join with id 1 and 0 eth
    vm.prank(alice);
    wethgateway.joinETH{value: amount}(id);
    assertEq(weth.balanceOf(address(mtoken)), amount);
    assertEq(mtoken.balanceOf(alice, id), mTokenAmount);
  }

  function testFailJoinETHWithWrongAmount() public {
    uint256 id = 0x3e8;
    uint256 amount = 10 ether;
    uint256 mTokenAmount = (amount * (10000 - downpaymentWETH)) / 10000;

    // join with id 1 and 10 eth + 1 wei
    vm.startPrank(alice);
    WETH9Mocked(payable(address(weth))).deposit{value: amount}();
    WETH9Mocked(payable(address(weth))).transferFrom(alice, address(moonpierproxy), amount);
    moonpierproxy.join(address(weth), id, amount + 1, alice);
    assertEq(weth.balanceOf(address(mtoken)), amount);
    assertEq(mtoken.balanceOf(alice, id), mTokenAmount);
  }

  function testFailJoinMoonPierWithoutWETH() public {
    uint256 id = 0x3e8;
    uint256 amount = 10 ether;

    vm.prank(alice);
    moonpierproxy.join(address(weth), id, amount, alice);
  }

  function testCannotjoinWithUnknowReserve() public {
    uint256 id = 0x3e8;
    uint256 amount = 10 ether;

    // join with id 1 and 10 unknown token
    address unknownToken = address(0x1);
    vm.expectRevert("Join: invalid reserve");
    vm.prank(alice);
    moonpierproxy.join(unknownToken, id, amount, alice);
  }

  function testCannotJoinAfterCollectionCreated() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x3E8;
    uint256 amount = 10 ether;

    string memory name = "name";
    string memory symbol = "NM";
    DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
      name: name,
      symbol: symbol,
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
      presaleEndTime: block.timestamp + 1000,
      metadataUri: "https://moonpier.art/"
    });
    vm.prank(creator);
    moonpierproxy.createCollection(address(weth), id, config);

    vm.expectRevert("Join: collection exists");
    vm.prank(alice);
    wethgateway.joinETH{value: amount}(id);
  }
}
