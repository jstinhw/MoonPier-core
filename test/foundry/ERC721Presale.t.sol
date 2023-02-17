// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/console2.sol";

import {BaseSetup} from "./BaseSetup.t.sol";
import {WETHGateway} from "../../contracts/core/WETHGateway.sol";
import {IMToken} from "../../contracts/interfaces/IMToken.sol";
import {DataTypes} from "../../contracts/libraries/DataTypes.sol";
import {IERC721Presale} from "../../contracts/interfaces/IERC721Presale.sol";
import {ERC721Presale} from "../../contracts/core/ERC721Presale.sol";
import {Errors} from "../../contracts/libraries/Errors.sol";
import {Utils} from "./utils.sol";

contract ERC721PresaleTest is BaseSetup {
  uint256 public downpaymentWETH = 10;
  Utils private utils = new Utils();

  function setUp() public virtual override {
    BaseSetup.setUp();
    moonfishproxy.addReserve(address(weth), downpaymentWETH, address(mtoken));
    wethgateway = new WETHGateway(address(weth), address(moonfishproxy));
  }

  function testPublicMint() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x01;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CollectionConfig memory config = DataTypes.CollectionConfig({
      fundsReceiver: creator,
      maxSupply: 10,
      maxAmountPerAddress: 1,
      publicMintPrice: 3 ether,
      publicStartTime: block.timestamp,
      publicEndTime: block.timestamp + 1000,
      whitelistStartTime: block.timestamp,
      whitelistEndTime: block.timestamp + 1000,
      presaleMaxSupply: 10,
      presaleMintPrice: 1 ether,
      presaleAmountPerWallet: 1
    });

    vm.prank(creator);
    moonfishproxy.createCollection(id, address(weth), name, symbol, config);
    ERC721Presale erc721presale = ERC721Presale(moonfishproxy.getCollectionData(id).collection);

    vm.prank(alice);
    erc721presale.mint{value: config.publicMintPrice}(1);
    assertEq(erc721presale.balanceOf(alice), 1);
    assertEq(erc721presale.ownerOf(0), alice);
  }

  function testCannotMintInsufficientETH() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x01;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CollectionConfig memory config = DataTypes.CollectionConfig({
      fundsReceiver: creator,
      maxSupply: 10,
      maxAmountPerAddress: 1,
      publicMintPrice: 3 ether,
      publicStartTime: block.timestamp,
      publicEndTime: block.timestamp - 1,
      whitelistStartTime: block.timestamp,
      whitelistEndTime: block.timestamp + 1000,
      presaleMaxSupply: 10,
      presaleMintPrice: 1 ether,
      presaleAmountPerWallet: 1
    });

    vm.prank(creator);
    moonfishproxy.createCollection(id, address(weth), name, symbol, config);
    ERC721Presale erc721presale = ERC721Presale(moonfishproxy.getCollectionData(id).collection);

    vm.prank(alice);
    vm.expectRevert(Errors.PublicMintInvalidTime.selector);
    erc721presale.mint{value: config.publicMintPrice - 1}(1);
  }

  function testCannotMintNotStarted() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x01;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CollectionConfig memory config = DataTypes.CollectionConfig({
      fundsReceiver: creator,
      maxSupply: 10,
      maxAmountPerAddress: 1,
      publicMintPrice: 3 ether,
      publicStartTime: block.timestamp,
      publicEndTime: block.timestamp - 1,
      whitelistStartTime: block.timestamp,
      whitelistEndTime: block.timestamp + 1000,
      presaleMaxSupply: 10,
      presaleMintPrice: 1 ether,
      presaleAmountPerWallet: 1
    });

    vm.prank(creator);
    moonfishproxy.createCollection(id, address(weth), name, symbol, config);
    ERC721Presale erc721presale = ERC721Presale(moonfishproxy.getCollectionData(id).collection);

    vm.prank(alice);
    vm.expectRevert(Errors.PublicMintInvalidTime.selector);
    erc721presale.mint{value: config.publicMintPrice}(1);
  }

  function testCannotMintEnded() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x01;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CollectionConfig memory config = DataTypes.CollectionConfig({
      fundsReceiver: creator,
      maxSupply: 10,
      maxAmountPerAddress: 1,
      publicMintPrice: 3 ether,
      publicStartTime: block.timestamp + 1,
      publicEndTime: block.timestamp + 1000,
      whitelistStartTime: block.timestamp,
      whitelistEndTime: block.timestamp + 1000,
      presaleMaxSupply: 10,
      presaleMintPrice: 1 ether,
      presaleAmountPerWallet: 1
    });

    vm.prank(creator);
    moonfishproxy.createCollection(id, address(weth), name, symbol, config);
    ERC721Presale erc721presale = ERC721Presale(moonfishproxy.getCollectionData(id).collection);

    vm.prank(alice);
    vm.expectRevert(Errors.PublicMintInvalidTime.selector);
    erc721presale.mint{value: config.publicMintPrice}(1);
  }

  function testCannotMintExceedAmountPerWallet() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x01;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CollectionConfig memory config = DataTypes.CollectionConfig({
      fundsReceiver: creator,
      maxSupply: 10,
      maxAmountPerAddress: 1,
      publicMintPrice: 3 ether,
      publicStartTime: block.timestamp,
      publicEndTime: block.timestamp + 1000,
      whitelistStartTime: block.timestamp,
      whitelistEndTime: block.timestamp + 1000,
      presaleMaxSupply: 10,
      presaleMintPrice: 1 ether,
      presaleAmountPerWallet: 1
    });

    vm.prank(creator);
    moonfishproxy.createCollection(id, address(weth), name, symbol, config);
    ERC721Presale erc721presale = ERC721Presale(moonfishproxy.getCollectionData(id).collection);

    vm.startPrank(alice);
    erc721presale.mint{value: config.publicMintPrice}(1);
    vm.expectRevert(Errors.PublicExceedMaxAMountPerAddress.selector);
    erc721presale.mint{value: config.publicMintPrice}(1);
  }

  function testCannotMintExceedMaxAmount() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x01;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CollectionConfig memory config = DataTypes.CollectionConfig({
      fundsReceiver: creator,
      maxSupply: 10,
      maxAmountPerAddress: 1,
      publicMintPrice: 3 ether,
      publicStartTime: block.timestamp,
      publicEndTime: block.timestamp + 1000,
      whitelistStartTime: block.timestamp,
      whitelistEndTime: block.timestamp + 1000,
      presaleMaxSupply: 10,
      presaleMintPrice: 1 ether,
      presaleAmountPerWallet: 1
    });

    vm.prank(creator);
    moonfishproxy.createCollection(id, address(weth), name, symbol, config);
    ERC721Presale erc721presale = ERC721Presale(moonfishproxy.getCollectionData(id).collection);

    address[] memory addresses = utils.createUsers(11);
    for (uint256 i = 1; i < addresses.length; i++) {
      vm.prank(addresses[i]);
      erc721presale.mint{value: config.publicMintPrice}(1);
    }
    assertEq(erc721presale.totalSupply(), 10);
    vm.expectRevert(Errors.InsufficientSupply.selector);
    vm.prank(addresses[0]);
    erc721presale.mint{value: config.publicMintPrice}(1);
    console2.log("alice:", alice);
    console2.log("bob:", bob);
    console2.log("cindy:", cindy);
  }

  function testWhitelistMint() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x01;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CollectionConfig memory config = DataTypes.CollectionConfig({
      fundsReceiver: creator,
      maxSupply: 10,
      maxAmountPerAddress: 1,
      publicMintPrice: 3 ether,
      publicStartTime: block.timestamp,
      publicEndTime: block.timestamp + 1000,
      whitelistStartTime: block.timestamp,
      whitelistEndTime: block.timestamp + 1000,
      presaleMaxSupply: 10,
      presaleMintPrice: 1 ether,
      presaleAmountPerWallet: 1
    });

    vm.startPrank(creator);
    Utils.Proof memory merkle = utils.getMerkleTree(0);
    moonfishproxy.createCollection(id, address(weth), name, symbol, config);
    ERC721Presale erc721presale = ERC721Presale(moonfishproxy.getCollectionData(id).collection);
    erc721presale.setMerkleRoot(merkle.root);
    vm.stopPrank();

    vm.prank(alice);
    erc721presale.whitelistMint{value: 1 ether}(merkle.proof, 1, 1, 1 ether);
    assertEq(erc721presale.balanceOf(alice), 1);
    assertEq(erc721presale.ownerOf(0), alice);
  }

  function testCannotWhitelistMintWrongMinter() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x01;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CollectionConfig memory config = DataTypes.CollectionConfig({
      fundsReceiver: creator,
      maxSupply: 10,
      maxAmountPerAddress: 1,
      publicMintPrice: 3 ether,
      publicStartTime: block.timestamp,
      publicEndTime: block.timestamp + 1000,
      whitelistStartTime: block.timestamp,
      whitelistEndTime: block.timestamp + 1000,
      presaleMaxSupply: 10,
      presaleMintPrice: 1 ether,
      presaleAmountPerWallet: 1
    });

    vm.startPrank(creator);
    Utils.Proof memory merkle = utils.getMerkleTree(0);
    moonfishproxy.createCollection(id, address(weth), name, symbol, config);
    ERC721Presale erc721presale = ERC721Presale(moonfishproxy.getCollectionData(id).collection);
    erc721presale.setMerkleRoot(merkle.root);
    vm.stopPrank();

    vm.expectRevert(Errors.WhitelistInvalidProof.selector);
    vm.prank(bob);
    erc721presale.whitelistMint{value: 1 ether}(merkle.proof, 1, 1, 1 ether);
  }

  function testCannotWhitelistMintWrongAmount() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x01;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CollectionConfig memory config = DataTypes.CollectionConfig({
      fundsReceiver: creator,
      maxSupply: 10,
      maxAmountPerAddress: 1,
      publicMintPrice: 3 ether,
      publicStartTime: block.timestamp,
      publicEndTime: block.timestamp + 1000,
      whitelistStartTime: block.timestamp,
      whitelistEndTime: block.timestamp + 1000,
      presaleMaxSupply: 10,
      presaleMintPrice: 1 ether,
      presaleAmountPerWallet: 1
    });

    vm.startPrank(creator);
    Utils.Proof memory merkle = utils.getMerkleTree(0);
    moonfishproxy.createCollection(id, address(weth), name, symbol, config);
    ERC721Presale erc721presale = ERC721Presale(moonfishproxy.getCollectionData(id).collection);
    erc721presale.setMerkleRoot(merkle.root);
    vm.stopPrank();

    vm.expectRevert(Errors.WhitelistInvalidProof.selector);
    vm.prank(alice);
    erc721presale.whitelistMint{value: 1 ether}(merkle.proof, 1, 2, 1 ether);
  }

  function testCannotWhitelistMintWrongPrice() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x01;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CollectionConfig memory config = DataTypes.CollectionConfig({
      fundsReceiver: creator,
      maxSupply: 10,
      maxAmountPerAddress: 1,
      publicMintPrice: 3 ether,
      publicStartTime: block.timestamp,
      publicEndTime: block.timestamp + 1000,
      whitelistStartTime: block.timestamp,
      whitelistEndTime: block.timestamp + 1000,
      presaleMaxSupply: 10,
      presaleMintPrice: 1 ether,
      presaleAmountPerWallet: 1
    });

    vm.startPrank(creator);
    Utils.Proof memory merkle = utils.getMerkleTree(0);
    moonfishproxy.createCollection(id, address(weth), name, symbol, config);
    ERC721Presale erc721presale = ERC721Presale(moonfishproxy.getCollectionData(id).collection);
    erc721presale.setMerkleRoot(merkle.root);
    vm.stopPrank();

    vm.expectRevert(Errors.WhitelistInvalidProof.selector);
    vm.prank(alice);
    erc721presale.whitelistMint{value: 1 ether}(merkle.proof, 1, 1, 0.5 ether);
  }

  function testCannotWhitelistMintInsufficientEth() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x01;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CollectionConfig memory config = DataTypes.CollectionConfig({
      fundsReceiver: creator,
      maxSupply: 10,
      maxAmountPerAddress: 1,
      publicMintPrice: 3 ether,
      publicStartTime: block.timestamp,
      publicEndTime: block.timestamp + 1000,
      whitelistStartTime: block.timestamp,
      whitelistEndTime: block.timestamp + 1000,
      presaleMaxSupply: 10,
      presaleMintPrice: 1 ether,
      presaleAmountPerWallet: 1
    });

    vm.startPrank(creator);
    Utils.Proof memory merkle = utils.getMerkleTree(0);
    moonfishproxy.createCollection(id, address(weth), name, symbol, config);
    ERC721Presale erc721presale = ERC721Presale(moonfishproxy.getCollectionData(id).collection);
    erc721presale.setMerkleRoot(merkle.root);
    vm.stopPrank();

    vm.prank(alice);
    vm.expectRevert(Errors.WhitelistInsufficientPrice.selector);
    erc721presale.whitelistMint{value: 0.5 ether}(merkle.proof, 1, 1, 1 ether);
  }

  function testCannotWhitelistMintNotStarted() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x01;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CollectionConfig memory config = DataTypes.CollectionConfig({
      fundsReceiver: creator,
      maxSupply: 10,
      maxAmountPerAddress: 1,
      publicMintPrice: 3 ether,
      publicStartTime: block.timestamp,
      publicEndTime: block.timestamp + 1000,
      whitelistStartTime: block.timestamp + 1,
      whitelistEndTime: block.timestamp + 1000,
      presaleMaxSupply: 10,
      presaleMintPrice: 1 ether,
      presaleAmountPerWallet: 1
    });

    vm.startPrank(creator);
    Utils.Proof memory merkle = utils.getMerkleTree(0);
    moonfishproxy.createCollection(id, address(weth), name, symbol, config);
    ERC721Presale erc721presale = ERC721Presale(moonfishproxy.getCollectionData(id).collection);
    erc721presale.setMerkleRoot(merkle.root);
    vm.stopPrank();

    vm.prank(alice);
    vm.expectRevert(Errors.WhitelistMintInvalidTime.selector);
    erc721presale.whitelistMint{value: 1 ether}(merkle.proof, 1, 1, 1 ether);
  }

  function testCannotWhitelistMintEnded() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x01;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CollectionConfig memory config = DataTypes.CollectionConfig({
      fundsReceiver: creator,
      maxSupply: 10,
      maxAmountPerAddress: 1,
      publicMintPrice: 3 ether,
      publicStartTime: block.timestamp,
      publicEndTime: block.timestamp + 1000,
      whitelistStartTime: block.timestamp,
      whitelistEndTime: block.timestamp - 1,
      presaleMaxSupply: 10,
      presaleMintPrice: 1 ether,
      presaleAmountPerWallet: 1
    });

    vm.startPrank(creator);
    Utils.Proof memory merkle = utils.getMerkleTree(0);
    moonfishproxy.createCollection(id, address(weth), name, symbol, config);
    ERC721Presale erc721presale = ERC721Presale(moonfishproxy.getCollectionData(id).collection);
    erc721presale.setMerkleRoot(merkle.root);
    vm.stopPrank();

    vm.prank(alice);
    vm.expectRevert(Errors.WhitelistMintInvalidTime.selector);
    erc721presale.whitelistMint{value: 1 ether}(merkle.proof, 1, 1, 1 ether);
  }

  function testCannotWhitelistMintExceedAvailableAmount() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x01;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CollectionConfig memory config = DataTypes.CollectionConfig({
      fundsReceiver: creator,
      maxSupply: 10,
      maxAmountPerAddress: 1,
      publicMintPrice: 3 ether,
      publicStartTime: block.timestamp,
      publicEndTime: block.timestamp + 1000,
      whitelistStartTime: block.timestamp,
      whitelistEndTime: block.timestamp + 1000,
      presaleMaxSupply: 10,
      presaleMintPrice: 1 ether,
      presaleAmountPerWallet: 1
    });

    vm.startPrank(creator);
    Utils.Proof memory merkle = utils.getMerkleTree(0);
    moonfishproxy.createCollection(id, address(weth), name, symbol, config);
    ERC721Presale erc721presale = ERC721Presale(moonfishproxy.getCollectionData(id).collection);
    erc721presale.setMerkleRoot(merkle.root);
    vm.stopPrank();

    vm.startPrank(alice);
    erc721presale.whitelistMint{value: 1 ether}(merkle.proof, 1, 1, 1 ether);
    vm.expectRevert(Errors.WhitelistExceedAvailableAmount.selector);
    erc721presale.whitelistMint{value: 1 ether}(merkle.proof, 1, 1, 1 ether);
  }

  function testCannotWhitelistMintExceedTotalAmount() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x01;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CollectionConfig memory config = DataTypes.CollectionConfig({
      fundsReceiver: creator,
      maxSupply: 10,
      maxAmountPerAddress: 1,
      publicMintPrice: 3 ether,
      publicStartTime: block.timestamp,
      publicEndTime: block.timestamp + 1000,
      whitelistStartTime: block.timestamp,
      whitelistEndTime: block.timestamp + 1000,
      presaleMaxSupply: 10,
      presaleMintPrice: 1 ether,
      presaleAmountPerWallet: 1
    });

    vm.startPrank(creator);
    Utils.Proof memory merkle = utils.getMerkleTree(0);
    moonfishproxy.createCollection(id, address(weth), name, symbol, config);
    ERC721Presale erc721presale = ERC721Presale(moonfishproxy.getCollectionData(id).collection);
    erc721presale.setMerkleRoot(merkle.root);
    vm.stopPrank();

    address[] memory addresses = utils.createUsers(11);
    for (uint256 i = 1; i < addresses.length; i++) {
      vm.prank(addresses[i]);
      erc721presale.mint{value: config.publicMintPrice}(1);
    }

    vm.startPrank(alice);
    vm.expectRevert(Errors.InsufficientSupply.selector);
    erc721presale.whitelistMint{value: 1 ether}(merkle.proof, 1, 1, 1 ether);
  }

  function testgetURI() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x01;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CollectionConfig memory config = DataTypes.CollectionConfig({
      fundsReceiver: creator,
      maxSupply: 10,
      maxAmountPerAddress: 1,
      publicMintPrice: 3 ether,
      publicStartTime: block.timestamp,
      publicEndTime: block.timestamp + 1000,
      whitelistStartTime: block.timestamp,
      whitelistEndTime: block.timestamp + 1000,
      presaleMaxSupply: 10,
      presaleMintPrice: 1 ether,
      presaleAmountPerWallet: 1
    });

    vm.startPrank(creator);
    Utils.Proof memory merkle = utils.getMerkleTree(0);
    moonfishproxy.createCollection(id, address(weth), name, symbol, config);
    ERC721Presale erc721presale = ERC721Presale(moonfishproxy.getCollectionData(id).collection);
    erc721presale.setMerkleRoot(merkle.root);
    assertEq(erc721presale.tokenURI(0), "");

    erc721presale.setBaseURI("https://moonfish.art/");
    assertEq(erc721presale.tokenURI(0), "https://moonfish.art/0");
  }

  function testWithdraw() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x01;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CollectionConfig memory config = DataTypes.CollectionConfig({
      fundsReceiver: creator,
      maxSupply: 10,
      maxAmountPerAddress: 1,
      publicMintPrice: 3 ether,
      publicStartTime: block.timestamp,
      publicEndTime: block.timestamp + 1000,
      whitelistStartTime: block.timestamp,
      whitelistEndTime: block.timestamp + 1000,
      presaleMaxSupply: 10,
      presaleMintPrice: 1 ether,
      presaleAmountPerWallet: 1
    });

    vm.prank(creator);
    moonfishproxy.createCollection(id, address(weth), name, symbol, config);
    ERC721Presale erc721presale = ERC721Presale(moonfishproxy.getCollectionData(id).collection);

    vm.prank(alice);
    erc721presale.mint{value: 3 ether}(1);
    (address feeOwner, uint256 fee) = feeManager.getFees(address(erc721presale));
    uint expectedBalance = (3 ether * (10000 - fee)) / 10000;
    uint adminFee = (3 ether * fee) / 10000;
    uint256 beforeCreatorBalance = creator.balance;
    uint256 beforeAdminBalance = admin.balance;
    vm.prank(creator);
    erc721presale.withdraw();
    uint256 afterCreatorBalance = creator.balance;
    uint256 afterAdminBalance = admin.balance;

    assertEq(feeOwner, admin);
    assertEq(afterAdminBalance - beforeAdminBalance, adminFee);
    assertEq(afterCreatorBalance - beforeCreatorBalance, expectedBalance);
  }

  function testCannotWithdrawNonCreator() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x01;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CollectionConfig memory config = DataTypes.CollectionConfig({
      fundsReceiver: creator,
      maxSupply: 10,
      maxAmountPerAddress: 1,
      publicMintPrice: 3 ether,
      publicStartTime: block.timestamp,
      publicEndTime: block.timestamp + 1000,
      whitelistStartTime: block.timestamp,
      whitelistEndTime: block.timestamp + 1000,
      presaleMaxSupply: 10,
      presaleMintPrice: 1 ether,
      presaleAmountPerWallet: 1
    });

    vm.prank(creator);
    moonfishproxy.createCollection(id, address(weth), name, symbol, config);
    ERC721Presale erc721presale = ERC721Presale(moonfishproxy.getCollectionData(id).collection);

    vm.startPrank(alice);
    erc721presale.mint{value: 3 ether}(1);
    vm.expectRevert(Errors.AdminOnly.selector);
    erc721presale.withdraw();
  }

  function testCannotSetMerkleRootNonCreator() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x01;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CollectionConfig memory config = DataTypes.CollectionConfig({
      fundsReceiver: creator,
      maxSupply: 10,
      maxAmountPerAddress: 1,
      publicMintPrice: 3 ether,
      publicStartTime: block.timestamp,
      publicEndTime: block.timestamp + 1000,
      whitelistStartTime: block.timestamp,
      whitelistEndTime: block.timestamp + 1000,
      presaleMaxSupply: 10,
      presaleMintPrice: 1 ether,
      presaleAmountPerWallet: 1
    });

    Utils.Proof memory merkle = utils.getMerkleTree(0);
    vm.prank(creator);
    moonfishproxy.createCollection(id, address(weth), name, symbol, config);
    ERC721Presale erc721presale = ERC721Presale(moonfishproxy.getCollectionData(id).collection);

    vm.startPrank(alice);
    vm.expectRevert(Errors.AdminOnly.selector);
    erc721presale.setMerkleRoot(merkle.root);
  }

  function testCannotSetURINotCreator() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x01;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CollectionConfig memory config = DataTypes.CollectionConfig({
      fundsReceiver: creator,
      maxSupply: 10,
      maxAmountPerAddress: 1,
      publicMintPrice: 3 ether,
      publicStartTime: block.timestamp,
      publicEndTime: block.timestamp + 1000,
      whitelistStartTime: block.timestamp,
      whitelistEndTime: block.timestamp + 1000,
      presaleMaxSupply: 10,
      presaleMintPrice: 1 ether,
      presaleAmountPerWallet: 1
    });

    vm.prank(creator);
    moonfishproxy.createCollection(id, address(weth), name, symbol, config);
    ERC721Presale erc721presale = ERC721Presale(moonfishproxy.getCollectionData(id).collection);

    vm.startPrank(alice);
    vm.expectRevert(Errors.AdminOnly.selector);
    erc721presale.setBaseURI("");
  }

  function testCannotSetConfigNotCreator() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x01;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CollectionConfig memory config = DataTypes.CollectionConfig({
      fundsReceiver: creator,
      maxSupply: 10,
      maxAmountPerAddress: 1,
      publicMintPrice: 3 ether,
      publicStartTime: block.timestamp,
      publicEndTime: block.timestamp + 1000,
      whitelistStartTime: block.timestamp,
      whitelistEndTime: block.timestamp + 1000,
      presaleMaxSupply: 10,
      presaleMintPrice: 1 ether,
      presaleAmountPerWallet: 1
    });

    vm.prank(creator);
    moonfishproxy.createCollection(id, address(weth), name, symbol, config);
    ERC721Presale erc721presale = ERC721Presale(moonfishproxy.getCollectionData(id).collection);

    vm.startPrank(alice);
    vm.expectRevert(Errors.AdminOnly.selector);
    erc721presale.setCollectionConfig(config);
  }

  function testUpdateImpl() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x01;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CollectionConfig memory config = DataTypes.CollectionConfig({
      fundsReceiver: creator,
      maxSupply: 10,
      maxAmountPerAddress: 1,
      publicMintPrice: 3 ether,
      publicStartTime: block.timestamp,
      publicEndTime: block.timestamp + 1000,
      whitelistStartTime: block.timestamp,
      whitelistEndTime: block.timestamp + 1000,
      presaleMaxSupply: 10,
      presaleMintPrice: 1 ether,
      presaleAmountPerWallet: 1
    });

    vm.prank(creator);
    moonfishproxy.createCollection(id, address(weth), name, symbol, config);
    ERC721Presale erc721presale = ERC721Presale(moonfishproxy.getCollectionData(id).collection);

    vm.startPrank(creator);
    erc721presale.upgradeTo(moonfishproxy.erc721implementation());
  }

  function testCannotUpdateImplNotCreator() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x01;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CollectionConfig memory config = DataTypes.CollectionConfig({
      fundsReceiver: creator,
      maxSupply: 10,
      maxAmountPerAddress: 1,
      publicMintPrice: 3 ether,
      publicStartTime: block.timestamp,
      publicEndTime: block.timestamp + 1000,
      whitelistStartTime: block.timestamp,
      whitelistEndTime: block.timestamp + 1000,
      presaleMaxSupply: 10,
      presaleMintPrice: 1 ether,
      presaleAmountPerWallet: 1
    });

    vm.prank(creator);
    moonfishproxy.createCollection(id, address(weth), name, symbol, config);
    ERC721Presale erc721presale = ERC721Presale(moonfishproxy.getCollectionData(id).collection);

    vm.startPrank(alice);
    vm.expectRevert(Errors.AdminOnly.selector);
    erc721presale.upgradeTo(alice);
  }
}
