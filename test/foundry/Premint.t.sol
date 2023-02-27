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
    moonfishproxy.addReserve(address(weth), address(mtoken));
    wethgateway = new WETHGateway(address(weth), address(moonfishproxy));
  }

  function testPremint() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 14) | 0x3E8;

    uint256 joinAmount = 1 ether;
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
    // alice join
    vm.prank(alice);
    wethgateway.joinETH{value: joinAmount}(id);

    // create create collection
    vm.prank(creator);
    moonfishproxy.createCollection(address(weth), id, name, symbol, config);

    // alice premint
    vm.startPrank(alice);
    mtoken.setApprovalForAll(address(wethgateway), true);
    wethgateway.premint(id, 1);
    assertEq(mtoken.balanceOf(creator, id), joinAmount);
    assertEq(mtoken.balanceOf(alice, id), 0);
    assertEq(IERC721(moonfishproxy.getCollectionData(id).collection).balanceOf(alice), 1);
    assertEq(IERC721(moonfishproxy.getCollectionData(id).collection).ownerOf(0), alice);
  }

  function testCannotPremintNotCreate() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 14) | 0x3E8;

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
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 14) | 0x3E8;

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

    // create create collection
    vm.prank(creator);
    moonfishproxy.createCollection(address(weth), id, name, symbol, config);

    // alice premint
    vm.startPrank(alice);
    mtoken.setApprovalForAll(address(wethgateway), true);
    vm.expectRevert(Errors.GatewayPremintInsufficientBalance.selector);
    wethgateway.premint(id, 1);
  }

  function testCannotPremintAfterLeave() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 14) | 0x3E8;

    uint256 joinAmount = 1 ether;
    uint256 mTokenAmount = (joinAmount * (10000 - downpaymentWETH)) / 10000;

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

    // alice join
    vm.prank(alice);
    wethgateway.joinETH{value: joinAmount}(id);

    // create create collection
    vm.prank(creator);
    moonfishproxy.createCollection(address(weth), id, name, symbol, config);

    // alice leave and premint
    vm.startPrank(alice);
    mtoken.setApprovalForAll(address(wethgateway), true);

    wethgateway.leaveETH(id, mTokenAmount, msg.sender);
    vm.expectRevert(Errors.GatewayPremintInsufficientBalance.selector);
    wethgateway.premint(id, 1);
  }

  function testCannotPremintFromMoonFishNotCreate() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 14) | 0x3E8;

    uint256 joinAmount = 1 ether;
    // alice join
    vm.prank(alice);
    wethgateway.joinETH{value: joinAmount}(id);

    // alice premint
    vm.startPrank(alice);
    mtoken.setApprovalForAll(address(moonfishproxy), true);
    vm.expectRevert(Errors.MoonFishCollectionNotExist.selector);
    moonfishproxy.premint(id, 1, msg.sender);
  }

  function testCannotPremintFromMoonFishNoJoin() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 14) | 0x3E8;

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

    // create create collection
    vm.prank(creator);
    moonfishproxy.createCollection(address(weth), id, name, symbol, config);

    // alice premint
    vm.startPrank(alice);
    mtoken.setApprovalForAll(address(moonfishproxy), true);
    vm.expectRevert(Errors.MoonFishPremintInsufficientBalance.selector);
    moonfishproxy.premint(id, 1, msg.sender);
  }
}