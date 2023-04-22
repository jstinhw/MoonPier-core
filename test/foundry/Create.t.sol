// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {BaseSetup} from "./BaseSetup.t.sol";
import {WETHGateway} from "../../contracts/core/WETHGateway.sol";
import {DataTypes} from "../../contracts/libraries/DataTypes.sol";
import {ERC721Presale} from "../../contracts/core/ERC721Presale.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract Create is BaseSetup {
  uint256 public downpaymentWETH = 1000;

  function setUp() public virtual override {
    BaseSetup.setUp();
    vm.startPrank(admin);
    moonpierproxy.addReserve(address(weth), address(mtoken));
    wethgateway = new WETHGateway(address(weth), address(moonpierproxy));
    vm.stopPrank();
  }

  function testCreateCollection() public {
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

    vm.prank(creator);
    moonpierproxy.createCollection(address(weth), id, config);
    address collectionAddress = moonpierproxy.getCollectionData(id).collection;

    assertEq(ERC721Presale(collectionAddress).name(), name);
    assertEq(ERC721Presale(collectionAddress).symbol(), symbol);
    assertEq(ERC721Presale(collectionAddress).getCollectionConfig().maxSupply, config.maxSupply);
  }

  function testCannotCreateCollectionInvalidID() public {
    uint256 id = 1;

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
    vm.expectRevert("Create: not creator");
    vm.prank(creator);
    moonpier.createCollection(address(weth), id, config);
  }

  function testCannotCreateCollectionNotCreator() public {
    uint256 id = (uint256(uint160(alice)) << 96) | (0x0 << 64) | 0x3E8;

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
    vm.expectRevert("Create: not creator");
    vm.prank(creator);
    moonpier.createCollection(address(weth), id, config);
  }

  function testCannotCreateCollectionInvalidmToken() public {
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
    vm.prank(admin);
    moonpierproxy.addReserve(address(weth), address(0));

    vm.prank(creator);
    vm.expectRevert("Create: invalid reserve");
    moonpierproxy.createCollection(address(weth), id, config);
  }

  function testCannotCreateCollectionExisting() public {
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

    vm.startPrank(creator);
    moonpierproxy.createCollection(address(weth), id, config);

    vm.expectRevert("Create: collection exists");
    moonpierproxy.createCollection(address(weth), id, config);
  }

  function testCreateCollectionDownPayment() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 16) | 0x3E8;
    uint256 joinAmount = 1 ether;
    uint256 premintedAmount = (joinAmount * (10000 - downpaymentWETH)) / 10000;
    uint256 downpayment = joinAmount - premintedAmount;

    // string memory name = "name";
    // string memory symbol = "NM";
    DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
      name: "name",
      symbol: "NM",
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

    uint256 expectedFee = (downpayment * 1000) / 10000;
    uint256 expectedDownpayment = downpayment - expectedFee;

    vm.prank(alice);
    wethgateway.joinETH{value: joinAmount}(id);
    vm.startPrank(creator);
    uint256 beforeBalanceCreator = IERC20(address(weth)).balanceOf(creator);
    uint256 beforeBalanceAdmin = IERC20(address(weth)).balanceOf(admin);
    moonpierproxy.createCollection(address(weth), id, config);

    uint256 afterBalanceCreator = IERC20(address(weth)).balanceOf(creator);
    uint256 afterBalanceAdmin = IERC20(address(weth)).balanceOf(admin);
    assertEq(mtoken.balanceOf(alice, id), premintedAmount);
    assertEq(afterBalanceCreator - beforeBalanceCreator, expectedDownpayment);
    assertEq(afterBalanceAdmin - beforeBalanceAdmin, expectedFee);
  }

  function testCreateCollectionDownPaymentFuzz(uint256 joinAmount) public {
    vm.assume(joinAmount > 0 && joinAmount < 100 ether);
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 16) | 0x3E8;
    uint256 premintedAmount = (joinAmount * (10000 - downpaymentWETH)) / 10000;
    uint256 downpayment = joinAmount - premintedAmount;

    // string memory name = "name";
    // string memory symbol = "NM";
    DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
      name: "name",
      symbol: "NM",
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

    uint256 expectedFee = (downpayment * 1000) / 10000;
    uint256 expectedDownpayment = downpayment - expectedFee;

    vm.prank(alice);
    wethgateway.joinETH{value: joinAmount}(id);

    vm.startPrank(creator);
    uint256 beforeBalanceCreator = IERC20(address(weth)).balanceOf(creator);
    uint256 beforeBalanceAdmin = IERC20(address(weth)).balanceOf(admin);
    moonpierproxy.createCollection(address(weth), id, config);

    uint256 afterBalanceCreator = IERC20(address(weth)).balanceOf(creator);
    uint256 afterBalanceAdmin = IERC20(address(weth)).balanceOf(admin);

    assertEq(mtoken.balanceOf(alice, id), premintedAmount);
    assertEq(afterBalanceCreator - beforeBalanceCreator, expectedDownpayment);
    assertEq(afterBalanceAdmin - beforeBalanceAdmin, expectedFee);
  }
}
