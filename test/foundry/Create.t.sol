// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {BaseSetup} from "./BaseSetup.t.sol";
import {WETHGateway} from "../../contracts/core/WETHGateway.sol";
import {DataTypes} from "../../contracts/libraries/DataTypes.sol";
import {ERC721Presale} from "../../contracts/core/ERC721Presale.sol";
import "forge-std/console2.sol";

contract Create is BaseSetup {
  uint256 public downpaymentWETH = 1000;

  function setUp() public virtual override {
    BaseSetup.setUp();
    moonfishproxy.addReserve(address(weth), address(mtoken));
    wethgateway = new WETHGateway(address(weth), address(moonfishproxy));
  }

  function testCreateCollection() public {
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

    vm.prank(creator);
    moonfishproxy.createCollection(address(weth), id, name, symbol, config);
    address collectionAddress = moonfishproxy.getCollectionData(id).collection;
    assertEq(ERC721Presale(collectionAddress).name(), name);
    assertEq(ERC721Presale(collectionAddress).symbol(), symbol);
    assertEq(ERC721Presale(collectionAddress).getConfig().maxSupply, config.maxSupply);
  }

  function testCannotCreateCollectionInvalidID() public {
    uint256 id = 1;

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
    vm.expectRevert("Create: not creator");
    vm.prank(creator);
    moonfish.createCollection(address(weth), id, name, symbol, config);
  }

  function testCannotCreateCollectionNotCreator() public {
    uint256 id = (uint256(uint160(alice)) << 96) | (0x0 << 64) | 0x3E8;

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
    vm.expectRevert("Create: not creator");
    vm.prank(creator);
    moonfish.createCollection(address(weth), id, name, symbol, config);
  }

  function testCannotCreateCollectionExisting() public {
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

    vm.startPrank(creator);
    moonfishproxy.createCollection(address(weth), id, name, symbol, config);

    vm.expectRevert("Create: collection exists");
    moonfishproxy.createCollection(address(weth), id, name, symbol, config);
  }

  function testCreateCollectionDownPayment() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 14) | 0x3E8;
    uint256 joinAmount = 1 ether;
    uint256 premintedAmount = (joinAmount * (10000 - downpaymentWETH)) / 10000;
    uint256 downpayment = joinAmount - premintedAmount;

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

    vm.prank(alice);
    wethgateway.joinETH{value: joinAmount}(id);
    vm.prank(creator);
    moonfishproxy.createCollection(address(weth), id, name, symbol, config);
    assertEq(mtoken.balanceOf(alice, id), premintedAmount);
    assertEq(mtoken.balanceOf(creator, id), downpayment);
  }

  function testCreateCollectionDownPaymentFuzz(uint256 joinAmount) public {
    vm.assume(joinAmount > 0 && joinAmount < 100 ether);
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 14) | 0x3E8;
    uint256 premintedAmount = (joinAmount * (10000 - downpaymentWETH)) / 10000;
    uint256 downpayment = joinAmount - premintedAmount;

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

    vm.prank(alice);
    wethgateway.joinETH{value: joinAmount}(id);
    vm.prank(creator);
    moonfishproxy.createCollection(address(weth), id, name, symbol, config);
    assertEq(mtoken.balanceOf(alice, id), premintedAmount);
    assertEq(mtoken.balanceOf(creator, id), downpayment);
  }
}