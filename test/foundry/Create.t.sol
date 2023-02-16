// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {BaseSetup} from "./BaseSetup.t.sol";
import {WETHGateway} from "../../contracts/core/WETHGateway.sol";
import {DataTypes} from "../../contracts/libraries/DataTypes.sol";
import {ERC721Presale} from "../../contracts/core/ERC721Presale.sol";

contract Create is BaseSetup {
  uint256 public downpaymentWETH = 10;

  function setUp() public virtual override {
    BaseSetup.setUp();
    moonfishproxy.addReserve(address(weth), downpaymentWETH, address(mtoken));
    wethgateway = new WETHGateway(address(weth), address(moonfishproxy));
  }

  function testCreateCollection() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x01;

    string memory name = "name";
    string memory symbol = "NM";
    DataTypes.CollectionConfig memory config = DataTypes.CollectionConfig({
      fundsReceiver: creator,
      maxSupply: 100,
      maxAmountPerAddress: 1,
      publicMintPrice: 3 ether,
      publicStartTime: block.timestamp,
      publicEndTime: block.timestamp + 1000,
      whitelistMintPrice: 2 ether,
      whitelistStartTime: block.timestamp,
      whitelistEndTime: block.timestamp + 1000,
      presaleMaxSupply: 10,
      presaleMintPrice: 1 ether,
      presaleAmountPerWallet: 1
    });

    vm.prank(creator);
    moonfishproxy.createCollection(id, address(weth), name, symbol, config);
    address collectionAddress = moonfishproxy.getCollectionData(id).collection;
    assertEq(ERC721Presale(collectionAddress).name(), name);
    assertEq(ERC721Presale(collectionAddress).symbol(), symbol);
    assertEq(ERC721Presale(collectionAddress).getConfig().maxSupply, config.maxSupply);
  }

  function testCannotCreateCollectionInvalidID() public {
    uint256 id = 1;

    string memory name = "name";
    string memory symbol = "NM";
    DataTypes.CollectionConfig memory config = DataTypes.CollectionConfig({
      fundsReceiver: creator,
      maxSupply: 100,
      maxAmountPerAddress: 1,
      publicMintPrice: 3 ether,
      publicStartTime: block.timestamp,
      publicEndTime: block.timestamp + 1000,
      whitelistMintPrice: 2 ether,
      whitelistStartTime: block.timestamp,
      whitelistEndTime: block.timestamp + 1000,
      presaleMaxSupply: 10,
      presaleMintPrice: 1 ether,
      presaleAmountPerWallet: 1
    });
    vm.expectRevert("Create: not creator");
    vm.prank(creator);
    moonfish.createCollection(id, address(weth), name, symbol, config);
  }

  function testCannotCreateCollectionNotCreator() public {
    uint256 id = (uint256(uint160(alice)) << 96) | (0x0 << 64) | 0x01;

    string memory name = "name";
    string memory symbol = "NM";
    DataTypes.CollectionConfig memory config = DataTypes.CollectionConfig({
      fundsReceiver: creator,
      maxSupply: 100,
      maxAmountPerAddress: 1,
      publicMintPrice: 3 ether,
      publicStartTime: block.timestamp,
      publicEndTime: block.timestamp + 1000,
      whitelistMintPrice: 2 ether,
      whitelistStartTime: block.timestamp,
      whitelistEndTime: block.timestamp + 1000,
      presaleMaxSupply: 10,
      presaleMintPrice: 1 ether,
      presaleAmountPerWallet: 1
    });
    vm.expectRevert("Create: not creator");
    vm.prank(creator);
    moonfish.createCollection(id, address(weth), name, symbol, config);
  }

  function testCannotCreateCollectionExisting() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x01;

    string memory name = "name";
    string memory symbol = "NM";
    DataTypes.CollectionConfig memory config = DataTypes.CollectionConfig({
      fundsReceiver: creator,
      maxSupply: 100,
      maxAmountPerAddress: 1,
      publicMintPrice: 3 ether,
      publicStartTime: block.timestamp,
      publicEndTime: block.timestamp + 1000,
      whitelistMintPrice: 2 ether,
      whitelistStartTime: block.timestamp,
      whitelistEndTime: block.timestamp + 1000,
      presaleMaxSupply: 10,
      presaleMintPrice: 1 ether,
      presaleAmountPerWallet: 1
    });

    vm.startPrank(creator);
    moonfishproxy.createCollection(id, address(weth), name, symbol, config);

    vm.expectRevert("Create: collection exists");
    moonfishproxy.createCollection(id, address(weth), name, symbol, config);
  }

  function testCreateCollectionDownPayment() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x01;
    uint256 joinAmount = 1 ether;
    uint256 premintedAmount = joinAmount * (100 - downpaymentWETH) / 100;
    uint256 downpayment = joinAmount - premintedAmount;

    string memory name = "name";
    string memory symbol = "NM";
    DataTypes.CollectionConfig memory config = DataTypes.CollectionConfig({
      fundsReceiver: creator,
      maxSupply: 100,
      maxAmountPerAddress: 1,
      publicMintPrice: 3 ether,
      publicStartTime: block.timestamp,
      publicEndTime: block.timestamp + 1000,
      whitelistMintPrice: 2 ether,
      whitelistStartTime: block.timestamp,
      whitelistEndTime: block.timestamp + 1000,
      presaleMaxSupply: 10,
      presaleMintPrice: 1 ether,
      presaleAmountPerWallet: 1
    });

    vm.prank(alice);
    wethgateway.joinETH{value: joinAmount}(id);
    vm.prank(creator);
    moonfishproxy.createCollection(id, address(weth), name, symbol, config);
    assertEq(mtoken.balanceOf(alice, id), premintedAmount);
    assertEq(mtoken.balanceOf(creator, id), downpayment);
  }

  function testCreateCollectionDownPaymentFuzz(uint256 joinAmount) public {
    vm.assume(joinAmount > 0 && joinAmount < 100 ether);
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x01;
    uint256 premintedAmount = joinAmount * (100 - downpaymentWETH) / 100;
    uint256 downpayment = joinAmount - premintedAmount;

    string memory name = "name";
    string memory symbol = "NM";
    DataTypes.CollectionConfig memory config = DataTypes.CollectionConfig({
      fundsReceiver: creator,
      maxSupply: 100,
      maxAmountPerAddress: 1,
      publicMintPrice: 3 ether,
      publicStartTime: block.timestamp,
      publicEndTime: block.timestamp + 1000,
      whitelistMintPrice: 2 ether,
      whitelistStartTime: block.timestamp,
      whitelistEndTime: block.timestamp + 1000,
      presaleMaxSupply: 10,
      presaleMintPrice: 1 ether,
      presaleAmountPerWallet: 1
    });

    vm.prank(alice);
    wethgateway.joinETH{value: joinAmount}(id);
    vm.prank(creator);
    moonfishproxy.createCollection(id, address(weth), name, symbol, config);
    assertEq(mtoken.balanceOf(alice, id), premintedAmount);
    assertEq(mtoken.balanceOf(creator, id), downpayment);
  }
}
