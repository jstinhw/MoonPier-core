// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {BaseSetup} from "./BaseSetup.t.sol";
import {WETHGateway} from "../../contracts/core/WETHGateway.sol";
import {DataTypes} from "../../contracts/libraries/DataTypes.sol";
import {ERC721Presale} from "../../contracts/core/ERC721Presale.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {Errors} from "../../contracts/libraries/Errors.sol";

contract Premint is BaseSetup {
  uint256 public downpaymentWETH = 1000;

  function setUp() public virtual override {
    BaseSetup.setUp();
    vm.startPrank(admin);
    moonpierproxy.addReserve(address(weth), address(mtoken));
    wethgateway = new WETHGateway(address(weth), address(moonpierproxy));
    vm.stopPrank();
  }

  function testPremint() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 16) | 0x3E8;

    uint256 joinAmount = 1 ether;
    uint256 premintedAmount = (joinAmount * (10000 - downpaymentWETH)) / 10000;

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
    // alice join
    vm.prank(alice);
    wethgateway.joinETH{value: joinAmount}(id);

    // create create collection
    vm.prank(creator);
    moonpierproxy.createCollection(address(weth), id, config);
    uint256 wethAdminBefore = weth.balanceOf(admin);
    uint256 wethCreatorBefore = weth.balanceOf(creator);

    uint256 expectedFee = (premintedAmount * 1000) / 10000;
    uint256 expectedPrice = premintedAmount - expectedFee;

    // alice premint
    vm.startPrank(alice);
    mtoken.setApprovalForAll(address(wethgateway), true);
    wethgateway.premint(id, 1);

    uint256 wethAdminAfter = weth.balanceOf(admin);
    uint256 wethCreatorAfter = weth.balanceOf(creator);

    assertEq(weth.balanceOf(alice), 0);
    assertEq(wethCreatorAfter - wethCreatorBefore, expectedPrice);
    assertEq(wethAdminAfter - wethAdminBefore, expectedFee);

    assertEq(IERC721(moonpierproxy.getCollectionData(id).collection).balanceOf(alice), 1);
    assertEq(IERC721(moonpierproxy.getCollectionData(id).collection).ownerOf(0), alice);
  }

  function testPremintZero() public {
    uint256 downpayment = 0;
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 16) | downpayment;

    uint256 joinAmount = 1 ether;
    uint256 premintedAmount = (joinAmount * (10000 - downpayment)) / 10000;

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
    // alice join
    vm.prank(alice);
    wethgateway.joinETH{value: joinAmount}(id);

    // create create collection
    vm.prank(creator);
    moonpierproxy.createCollection(address(weth), id, config);
    uint256 wethAdminBefore = weth.balanceOf(admin);
    uint256 wethCreatorBefore = weth.balanceOf(creator);

    uint256 expectedFee = (premintedAmount * 1000) / 10000;
    uint256 expectedPrice = premintedAmount - expectedFee;

    // alice premint
    vm.startPrank(alice);
    mtoken.setApprovalForAll(address(wethgateway), true);
    wethgateway.premint(id, 1);

    uint256 wethAdminAfter = weth.balanceOf(admin);
    uint256 wethCreatorAfter = weth.balanceOf(creator);

    assertEq(weth.balanceOf(alice), 0);
    assertEq(wethCreatorAfter - wethCreatorBefore, expectedPrice);
    assertEq(wethAdminAfter - wethAdminBefore, expectedFee);

    assertEq(IERC721(moonpierproxy.getCollectionData(id).collection).balanceOf(alice), 1);
    assertEq(IERC721(moonpierproxy.getCollectionData(id).collection).ownerOf(0), alice);
  }

  function testCannotPremintNotCreate() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 16) | 0x3E8;

    uint256 joinAmount = 1 ether;
    // alice join
    vm.prank(alice);
    wethgateway.joinETH{value: joinAmount}(id);

    // alice premint
    vm.startPrank(alice);
    mtoken.setApprovalForAll(address(wethgateway), true);
    vm.expectRevert(Errors.CollectionNotExist.selector);
    wethgateway.premint(id, 1);
  }

  function testCannotPremintNoJoin() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 16) | 0x3E8;

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

    // create create collection
    vm.prank(creator);
    moonpierproxy.createCollection(address(weth), id, config);

    // alice premint
    vm.startPrank(alice);
    mtoken.setApprovalForAll(address(wethgateway), true);
    vm.expectRevert(Errors.GatewayPremintInsufficientBalance.selector);
    wethgateway.premint(id, 1);
  }

  function testCannotPremintAfterLeave() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 16) | 0x3E8;

    uint256 joinAmount = 1 ether;
    uint256 mTokenAmount = (joinAmount * (10000 - downpaymentWETH)) / 10000;

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

    // alice join
    vm.prank(alice);
    wethgateway.joinETH{value: joinAmount}(id);

    // create create collection
    vm.prank(creator);
    moonpierproxy.createCollection(address(weth), id, config);

    // alice leave and premint
    vm.startPrank(alice);
    mtoken.setApprovalForAll(address(wethgateway), true);

    wethgateway.leaveETH(id, mTokenAmount, msg.sender);
    vm.expectRevert(Errors.GatewayPremintInsufficientBalance.selector);
    wethgateway.premint(id, 1);
  }

  function testCannotPremintFromMoonPierNotCreate() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 16) | 0x3E8;

    uint256 joinAmount = 1 ether;
    // alice join
    vm.prank(alice);
    wethgateway.joinETH{value: joinAmount}(id);

    // alice premint
    vm.startPrank(alice);
    mtoken.setApprovalForAll(address(moonpierproxy), true);
    vm.expectRevert(Errors.CollectionNotExist.selector);
    moonpierproxy.premint(id, 1, msg.sender);
  }

  function testCannotPremintFromMoonPierNoJoin() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 16) | 0x3E8;

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

    // create create collection
    vm.prank(creator);
    moonpierproxy.createCollection(address(weth), id, config);

    // alice premint
    vm.startPrank(alice);
    mtoken.setApprovalForAll(address(moonpierproxy), true);
    vm.expectRevert(Errors.PremintInsufficientBalance.selector);
    moonpierproxy.premint(id, 1, msg.sender);
  }
}
