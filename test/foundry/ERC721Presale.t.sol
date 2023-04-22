// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {BaseSetup} from "./BaseSetup.t.sol";
import {WETHGateway} from "../../contracts/core/WETHGateway.sol";
import {IMToken} from "../../contracts/interfaces/IMToken.sol";
import {DataTypes} from "../../contracts/libraries/DataTypes.sol";
import {IERC721Presale} from "../../contracts/interfaces/IERC721Presale.sol";
import {ERC721Presale} from "../../contracts/core/ERC721Presale.sol";
import {Errors} from "../../contracts/libraries/Errors.sol";
import {Utils} from "./utils.sol";

import {IERC165Upgradeable} from "openzeppelin-upgradeable/contracts/interfaces/IERC165Upgradeable.sol";

contract ERC721PresaleTest is BaseSetup {
  uint256 public downpaymentWETH = 1000;
  Utils private utils = new Utils();

  function setUp() public virtual override {
    BaseSetup.setUp();
    vm.startPrank(admin);
    moonpierproxy.addReserve(address(weth), address(mtoken));
    wethgateway = new WETHGateway(address(weth), address(moonpierproxy));
    vm.stopPrank();
  }

  function testPublicMint() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x3E8;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
      name: name,
      symbol: symbol,
      fundsReceiver: creator,
      maxSupply: 10,
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
    ERC721Presale erc721presale = ERC721Presale(moonpierproxy.getCollectionData(id).collection);

    vm.prank(alice);
    erc721presale.mint{value: config.publicMintPrice}(1);
    assertEq(erc721presale.balanceOf(alice), 1);
    assertEq(erc721presale.ownerOf(0), alice);
  }

  function testCannotMintInsufficientETH() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x3E8;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
      name: name,
      symbol: symbol,
      fundsReceiver: creator,
      maxSupply: 10,
      maxAmountPerAddress: 1,
      publicMintPrice: 3 ether,
      publicStartTime: block.timestamp,
      publicEndTime: block.timestamp + 1,
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
    ERC721Presale erc721presale = ERC721Presale(moonpierproxy.getCollectionData(id).collection);

    vm.prank(alice);
    vm.expectRevert(Errors.InsufficientEth.selector);
    erc721presale.mint{value: config.publicMintPrice - 1}(1);
  }

  function testCannotMintNotStarted() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x3E8;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
      name: name,
      symbol: symbol,
      fundsReceiver: creator,
      maxSupply: 10,
      maxAmountPerAddress: 1,
      publicMintPrice: 3 ether,
      publicStartTime: block.timestamp,
      publicEndTime: block.timestamp - 1,
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
    ERC721Presale erc721presale = ERC721Presale(moonpierproxy.getCollectionData(id).collection);

    vm.prank(alice);
    vm.expectRevert(Errors.InvalidPublicMintTime.selector);
    erc721presale.mint{value: config.publicMintPrice}(1);
  }

  function testCannotMintEnded() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x3E8;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
      name: name,
      symbol: symbol,
      fundsReceiver: creator,
      maxSupply: 10,
      maxAmountPerAddress: 1,
      publicMintPrice: 3 ether,
      publicStartTime: block.timestamp + 1,
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
    ERC721Presale erc721presale = ERC721Presale(moonpierproxy.getCollectionData(id).collection);

    vm.prank(alice);
    vm.expectRevert(Errors.InvalidPublicMintTime.selector);
    erc721presale.mint{value: config.publicMintPrice}(1);
  }

  function testCannotMintExceedAmountPerWallet() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x3E8;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
      name: name,
      symbol: symbol,
      fundsReceiver: creator,
      maxSupply: 10,
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
    ERC721Presale erc721presale = ERC721Presale(moonpierproxy.getCollectionData(id).collection);

    vm.startPrank(alice);
    erc721presale.mint{value: config.publicMintPrice}(1);
    vm.expectRevert(Errors.ExceedMaxAmountPerAddress.selector);
    erc721presale.mint{value: config.publicMintPrice}(1);
  }

  function testCannotMintExceedMaxAmount() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x3E8;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
      name: name,
      symbol: symbol,
      fundsReceiver: creator,
      maxSupply: 10,
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
    ERC721Presale erc721presale = ERC721Presale(moonpierproxy.getCollectionData(id).collection);

    address[] memory addresses = utils.createUsers(11);
    for (uint256 i = 1; i < addresses.length; i++) {
      vm.prank(addresses[i]);
      erc721presale.mint{value: config.publicMintPrice}(1);
    }
    assertEq(erc721presale.totalSupply(), 10);
    vm.expectRevert(Errors.ExceedMaxSupply.selector);
    vm.prank(addresses[0]);
    erc721presale.mint{value: config.publicMintPrice}(1);
  }

  function testWhitelistMint() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x3E8;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
      name: name,
      symbol: symbol,
      fundsReceiver: creator,
      maxSupply: 10,
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
    Utils.Proof memory merkle = utils.getMerkleTree(0);
    moonpierproxy.createCollection(address(weth), id, config);
    ERC721Presale erc721presale = ERC721Presale(moonpierproxy.getCollectionData(id).collection);
    erc721presale.setMerkleRoot(merkle.root);
    vm.stopPrank();

    vm.prank(alice);
    erc721presale.whitelistMint{value: 1 ether}(merkle.proof, 1, 1, 1 ether);
    assertEq(erc721presale.balanceOf(alice), 1);
    assertEq(erc721presale.ownerOf(0), alice);
    assertEq(erc721presale.getWhitelistMintedAmount(alice), 1);
  }

  function testCannotWhitelistMintWrongMinter() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x3E8;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
      name: name,
      symbol: symbol,
      fundsReceiver: creator,
      maxSupply: 10,
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
    Utils.Proof memory merkle = utils.getMerkleTree(0);
    moonpierproxy.createCollection(address(weth), id, config);
    ERC721Presale erc721presale = ERC721Presale(moonpierproxy.getCollectionData(id).collection);
    erc721presale.setMerkleRoot(merkle.root);
    vm.stopPrank();

    vm.expectRevert(Errors.InvalidWhitelistProof.selector);
    vm.prank(bob);
    erc721presale.whitelistMint{value: 1 ether}(merkle.proof, 1, 1, 1 ether);
  }

  function testCannotWhitelistMintWrongAmount() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x3E8;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
      name: name,
      symbol: symbol,
      fundsReceiver: creator,
      maxSupply: 10,
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
    Utils.Proof memory merkle = utils.getMerkleTree(0);
    moonpierproxy.createCollection(address(weth), id, config);
    ERC721Presale erc721presale = ERC721Presale(moonpierproxy.getCollectionData(id).collection);
    erc721presale.setMerkleRoot(merkle.root);
    vm.stopPrank();

    vm.expectRevert(Errors.InvalidWhitelistProof.selector);
    vm.prank(alice);
    erc721presale.whitelistMint{value: 1 ether}(merkle.proof, 1, 2, 1 ether);
  }

  function testCannotWhitelistMintWrongPrice() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x3E8;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
      name: name,
      symbol: symbol,
      fundsReceiver: creator,
      maxSupply: 10,
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
    Utils.Proof memory merkle = utils.getMerkleTree(0);
    moonpierproxy.createCollection(address(weth), id, config);
    ERC721Presale erc721presale = ERC721Presale(moonpierproxy.getCollectionData(id).collection);
    erc721presale.setMerkleRoot(merkle.root);
    vm.stopPrank();

    vm.expectRevert(Errors.InvalidWhitelistProof.selector);
    vm.prank(alice);
    erc721presale.whitelistMint{value: 1 ether}(merkle.proof, 1, 1, 0.5 ether);
  }

  function testCannotWhitelistMintInsufficientEth() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x3E8;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
      name: name,
      symbol: symbol,
      fundsReceiver: creator,
      maxSupply: 10,
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
    Utils.Proof memory merkle = utils.getMerkleTree(0);
    moonpierproxy.createCollection(address(weth), id, config);
    ERC721Presale erc721presale = ERC721Presale(moonpierproxy.getCollectionData(id).collection);
    erc721presale.setMerkleRoot(merkle.root);
    vm.stopPrank();

    vm.prank(alice);
    vm.expectRevert(Errors.InsufficientEth.selector);
    erc721presale.whitelistMint{value: 0.5 ether}(merkle.proof, 1, 1, 1 ether);
  }

  function testCannotWhitelistMintNotStarted() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x3E8;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
      name: name,
      symbol: symbol,
      fundsReceiver: creator,
      maxSupply: 10,
      maxAmountPerAddress: 1,
      publicMintPrice: 3 ether,
      publicStartTime: block.timestamp,
      publicEndTime: block.timestamp + 1000,
      whitelistStartTime: block.timestamp + 1,
      whitelistEndTime: block.timestamp + 1000,
      presaleMaxSupply: 10,
      presalePrice: 1 ether,
      presaleAmountPerWallet: 1,
      presaleStartTime: block.timestamp,
      presaleEndTime: block.timestamp + 1000,
      metadataUri: "https://moonpier.art/"
    });

    vm.startPrank(creator);
    Utils.Proof memory merkle = utils.getMerkleTree(0);
    moonpierproxy.createCollection(address(weth), id, config);
    ERC721Presale erc721presale = ERC721Presale(moonpierproxy.getCollectionData(id).collection);
    erc721presale.setMerkleRoot(merkle.root);
    vm.stopPrank();

    vm.prank(alice);
    vm.expectRevert(Errors.InvalidWhitelistMintTime.selector);
    erc721presale.whitelistMint{value: 1 ether}(merkle.proof, 1, 1, 1 ether);
  }

  function testCannotWhitelistMintEnded() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x3E8;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
      name: name,
      symbol: symbol,
      fundsReceiver: creator,
      maxSupply: 10,
      maxAmountPerAddress: 1,
      publicMintPrice: 3 ether,
      publicStartTime: block.timestamp,
      publicEndTime: block.timestamp + 1000,
      whitelistStartTime: block.timestamp,
      whitelistEndTime: block.timestamp - 1,
      presaleMaxSupply: 10,
      presalePrice: 1 ether,
      presaleAmountPerWallet: 1,
      presaleStartTime: block.timestamp,
      presaleEndTime: block.timestamp + 1000,
      metadataUri: "https://moonpier.art/"
    });

    vm.startPrank(creator);
    Utils.Proof memory merkle = utils.getMerkleTree(0);
    moonpierproxy.createCollection(address(weth), id, config);
    ERC721Presale erc721presale = ERC721Presale(moonpierproxy.getCollectionData(id).collection);
    erc721presale.setMerkleRoot(merkle.root);
    vm.stopPrank();

    vm.prank(alice);
    vm.expectRevert(Errors.InvalidWhitelistMintTime.selector);
    erc721presale.whitelistMint{value: 1 ether}(merkle.proof, 1, 1, 1 ether);
  }

  function testCannotWhitelistMintExceedAvailableAmount() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x3E8;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
      name: name,
      symbol: symbol,
      fundsReceiver: creator,
      maxSupply: 10,
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
    Utils.Proof memory merkle = utils.getMerkleTree(0);
    moonpierproxy.createCollection(address(weth), id, config);
    ERC721Presale erc721presale = ERC721Presale(moonpierproxy.getCollectionData(id).collection);
    erc721presale.setMerkleRoot(merkle.root);
    vm.stopPrank();

    vm.startPrank(alice);
    erc721presale.whitelistMint{value: 1 ether}(merkle.proof, 1, 1, 1 ether);
    vm.expectRevert(Errors.ExceedWhitelistAvailableAmount.selector);
    erc721presale.whitelistMint{value: 1 ether}(merkle.proof, 1, 1, 1 ether);
  }

  function testCannotWhitelistMintExceedTotalAmount() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x3E8;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
      name: name,
      symbol: symbol,
      fundsReceiver: creator,
      maxSupply: 10,
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
    Utils.Proof memory merkle = utils.getMerkleTree(0);
    moonpierproxy.createCollection(address(weth), id, config);
    ERC721Presale erc721presale = ERC721Presale(moonpierproxy.getCollectionData(id).collection);
    erc721presale.setMerkleRoot(merkle.root);
    vm.stopPrank();

    address[] memory addresses = utils.createUsers(11);
    for (uint256 i = 1; i < addresses.length; i++) {
      vm.prank(addresses[i]);
      erc721presale.mint{value: config.publicMintPrice}(1);
    }

    vm.startPrank(alice);
    vm.expectRevert(Errors.ExceedMaxSupply.selector);
    erc721presale.whitelistMint{value: 1 ether}(merkle.proof, 1, 1, 1 ether);
  }

  function testPresale() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x3E8;

    string memory name = "name";
    string memory symbol = "NM";
    vm.prank(alice);

    DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
      name: name,
      symbol: symbol,
      fundsReceiver: creator,
      maxSupply: 10,
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
    vm.stopPrank();
    vm.prank(creator);
    moonpierproxy.createCollection(address(weth), id, config);
    ERC721Presale erc721presale = ERC721Presale(moonpierproxy.getCollectionData(id).collection);

    vm.prank(address(moonpierproxy));
    erc721presale.presaleMint(alice, 1);
    assertEq(erc721presale.balanceOf(alice), 1);
    assertEq(erc721presale.ownerOf(0), alice);
    assertEq(erc721presale.getPresaleMintedAmount(alice), 1);
  }

  function testCannotPresaleNotMoonPier() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x3E8;

    string memory name = "name";
    string memory symbol = "NM";
    vm.prank(alice);

    DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
      name: name,
      symbol: symbol,
      fundsReceiver: creator,
      maxSupply: 10,
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
    vm.stopPrank();
    vm.prank(creator);
    moonpierproxy.createCollection(address(weth), id, config);
    ERC721Presale erc721presale = ERC721Presale(moonpierproxy.getCollectionData(id).collection);

    vm.expectRevert(Errors.MoonPierOnly.selector);
    erc721presale.presaleMint(alice, 1);
  }

  function testCannotPresaleHasNotStarted() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x3E8;

    string memory name = "name";
    string memory symbol = "NM";
    vm.prank(alice);

    DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
      name: name,
      symbol: symbol,
      fundsReceiver: creator,
      maxSupply: 10,
      maxAmountPerAddress: 1,
      publicMintPrice: 3 ether,
      publicStartTime: block.timestamp,
      publicEndTime: block.timestamp + 1000,
      whitelistStartTime: block.timestamp,
      whitelistEndTime: block.timestamp + 1000,
      presaleMaxSupply: 10,
      presalePrice: 1 ether,
      presaleAmountPerWallet: 1,
      presaleStartTime: block.timestamp + 1,
      presaleEndTime: block.timestamp + 1000,
      metadataUri: "https://moonpier.art/"
    });
    vm.stopPrank();
    vm.prank(creator);
    moonpierproxy.createCollection(address(weth), id, config);
    ERC721Presale erc721presale = ERC721Presale(moonpierproxy.getCollectionData(id).collection);

    vm.prank(address(moonpierproxy));
    vm.expectRevert(Errors.InvalidPresaleMintTime.selector);
    erc721presale.presaleMint(alice, 1);
  }

  function testCannotPresaleHasEnded() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x3E8;

    string memory name = "name";
    string memory symbol = "NM";
    vm.prank(alice);

    DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
      name: name,
      symbol: symbol,
      fundsReceiver: creator,
      maxSupply: 10,
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
      presaleEndTime: block.timestamp - 1,
      metadataUri: "https://moonpier.art/"
    });
    vm.stopPrank();
    vm.prank(creator);
    moonpierproxy.createCollection(address(weth), id, config);
    ERC721Presale erc721presale = ERC721Presale(moonpierproxy.getCollectionData(id).collection);

    vm.prank(address(moonpierproxy));
    vm.expectRevert(Errors.InvalidPresaleMintTime.selector);
    erc721presale.presaleMint(alice, 1);
  }

  function testCannotPresaleExceedMaxSupply() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x3E8;

    string memory name = "name";
    string memory symbol = "NM";
    vm.prank(alice);

    DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
      name: name,
      symbol: symbol,
      fundsReceiver: creator,
      maxSupply: 10,
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
    vm.stopPrank();
    vm.prank(creator);
    moonpierproxy.createCollection(address(weth), id, config);
    ERC721Presale erc721presale = ERC721Presale(moonpierproxy.getCollectionData(id).collection);

    address[] memory addresses = utils.createUsers(11);
    for (uint256 i = 1; i < addresses.length; i++) {
      vm.prank(addresses[i]);
      erc721presale.mint{value: config.publicMintPrice}(1);
    }
    vm.prank(address(moonpierproxy));
    vm.expectRevert(Errors.ExceedMaxSupply.selector);
    erc721presale.presaleMint(alice, 1);
  }

  function testCannotPresaleExceedPresaleAmount() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x3E8;

    string memory name = "name";
    string memory symbol = "NM";
    vm.prank(alice);

    DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
      name: name,
      symbol: symbol,
      fundsReceiver: creator,
      maxSupply: 10,
      maxAmountPerAddress: 2,
      publicMintPrice: 3 ether,
      publicStartTime: block.timestamp,
      publicEndTime: block.timestamp + 1000,
      whitelistStartTime: block.timestamp,
      whitelistEndTime: block.timestamp + 1000,
      presaleMaxSupply: 2,
      presalePrice: 1 ether,
      presaleAmountPerWallet: 2,
      presaleStartTime: block.timestamp,
      presaleEndTime: block.timestamp + 1000,
      metadataUri: "https://moonpier.art/"
    });
    vm.stopPrank();
    vm.prank(creator);
    moonpierproxy.createCollection(address(weth), id, config);
    ERC721Presale erc721presale = ERC721Presale(moonpierproxy.getCollectionData(id).collection);

    vm.startPrank(address(moonpierproxy));
    erc721presale.presaleMint(alice, 2);

    vm.expectRevert(Errors.ExceedPresaleMaxAmount.selector);
    erc721presale.presaleMint(bob, 1);
  }

  function testCannotPresaleExceedAmountPerAddress() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x3E8;

    string memory name = "name";
    string memory symbol = "NM";
    vm.prank(alice);

    DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
      name: name,
      symbol: symbol,
      fundsReceiver: creator,
      maxSupply: 10,
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
    vm.stopPrank();
    vm.prank(creator);
    moonpierproxy.createCollection(address(weth), id, config);
    ERC721Presale erc721presale = ERC721Presale(moonpierproxy.getCollectionData(id).collection);

    vm.startPrank(address(moonpierproxy));
    erc721presale.presaleMint(alice, 1);
    vm.expectRevert(Errors.ExceedPresaleMaxAmountPerAddress.selector);
    erc721presale.presaleMint(alice, 1);
  }

  function testCannotPresaleExceedTotalAmountPerAddress() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x3E8;

    string memory name = "name";
    string memory symbol = "NM";
    vm.prank(alice);

    DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
      name: name,
      symbol: symbol,
      fundsReceiver: creator,
      maxSupply: 10,
      maxAmountPerAddress: 2,
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
    vm.stopPrank();
    vm.prank(creator);
    moonpierproxy.createCollection(address(weth), id, config);
    ERC721Presale erc721presale = ERC721Presale(moonpierproxy.getCollectionData(id).collection);

    vm.prank(alice);
    erc721presale.mint{value: 6 ether}(2);

    vm.startPrank(address(moonpierproxy));
    vm.expectRevert(Errors.ExceedMaxAmountPerAddress.selector);
    erc721presale.presaleMint(alice, 1);
  }

  function testGetMerkleRoot() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x3E8;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
      name: name,
      symbol: symbol,
      fundsReceiver: creator,
      maxSupply: 10,
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
    Utils.Proof memory merkle = utils.getMerkleTree(0);
    moonpierproxy.createCollection(address(weth), id, config);
    ERC721Presale erc721presale = ERC721Presale(moonpierproxy.getCollectionData(id).collection);

    assertEq(erc721presale.getMerkleRoot(), "");
    // set Merkle root
    erc721presale.setMerkleRoot(merkle.root);
    assertEq(erc721presale.getMerkleRoot(), merkle.root);
  }

  function testGetURI() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x3E8;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
      name: name,
      symbol: symbol,
      fundsReceiver: creator,
      maxSupply: 10,
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
    Utils.Proof memory merkle = utils.getMerkleTree(0);
    moonpierproxy.createCollection(address(weth), id, config);
    ERC721Presale erc721presale = ERC721Presale(moonpierproxy.getCollectionData(id).collection);
    erc721presale.mint{value: 3 ether}(1);

    assertEq(erc721presale.tokenURI(0), "https://moonpier.art/0");

    erc721presale.setMerkleRoot(merkle.root);
    erc721presale.setBaseURI("https://moonpier.artie/");
    assertEq(erc721presale.tokenURI(0), "https://moonpier.artie/0");
  }

  function testCannotGetURITokenNotExist() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x3E8;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
      name: name,
      symbol: symbol,
      fundsReceiver: creator,
      maxSupply: 10,
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
    ERC721Presale erc721presale = ERC721Presale(moonpierproxy.getCollectionData(id).collection);

    vm.expectRevert(Errors.TokenNotExist.selector);
    erc721presale.tokenURI(0);
  }

  function testWithdraw() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x3E8;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
      name: name,
      symbol: symbol,
      fundsReceiver: creator,
      maxSupply: 10,
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
    ERC721Presale erc721presale = ERC721Presale(moonpierproxy.getCollectionData(id).collection);

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
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x3E8;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
      name: name,
      symbol: symbol,
      fundsReceiver: creator,
      maxSupply: 10,
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
    ERC721Presale erc721presale = ERC721Presale(moonpierproxy.getCollectionData(id).collection);

    vm.startPrank(alice);
    erc721presale.mint{value: 3 ether}(1);
    vm.expectRevert(Errors.CreatorOnly.selector);
    erc721presale.withdraw();
  }

  function testCannotWithdrawFundsFail() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x3E8;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
      name: name,
      symbol: symbol,
      fundsReceiver: address(feeManager),
      maxSupply: 10,
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
    ERC721Presale erc721presale = ERC721Presale(moonpierproxy.getCollectionData(id).collection);

    vm.prank(alice);
    erc721presale.mint{value: 3 ether}(1);

    vm.startPrank(creator);
    vm.expectRevert(Errors.WithdrawFundFailed.selector);
    erc721presale.withdraw();
  }

  function testCannotWithdrawFeeFail() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x3E8;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
      name: name,
      symbol: symbol,
      fundsReceiver: creator,
      maxSupply: 10,
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
    ERC721Presale erc721presale = ERC721Presale(moonpierproxy.getCollectionData(id).collection);

    vm.prank(alice);
    erc721presale.mint{value: 3 ether}(1);

    vm.prank(admin);
    feeManager.transferOwnership(address(feeManager));

    vm.startPrank(creator);
    vm.expectRevert(Errors.WithdrawFeeFailed.selector);
    erc721presale.withdraw();
  }

  function testCannotSetMerkleRootNonCreator() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x3E8;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
      name: name,
      symbol: symbol,
      fundsReceiver: creator,
      maxSupply: 10,
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

    Utils.Proof memory merkle = utils.getMerkleTree(0);
    vm.prank(creator);
    moonpierproxy.createCollection(address(weth), id, config);
    ERC721Presale erc721presale = ERC721Presale(moonpierproxy.getCollectionData(id).collection);

    vm.startPrank(alice);
    vm.expectRevert(Errors.CreatorOnly.selector);
    erc721presale.setMerkleRoot(merkle.root);
  }

  function testCannotSetURINotCreator() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x3E8;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
      name: name,
      symbol: symbol,
      fundsReceiver: creator,
      maxSupply: 10,
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
    ERC721Presale erc721presale = ERC721Presale(moonpierproxy.getCollectionData(id).collection);

    vm.startPrank(alice);
    vm.expectRevert(Errors.CreatorOnly.selector);
    erc721presale.setBaseURI("");
  }

  function testSetConfig() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x3E8;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
      name: name,
      symbol: symbol,
      fundsReceiver: creator,
      maxSupply: 10,
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
    ERC721Presale erc721presale = ERC721Presale(moonpierproxy.getCollectionData(id).collection);

    erc721presale.setCollectionConfig(
      DataTypes.CollectionConfig({
        fundsReceiver: creator,
        maxSupply: 100,
        maxAmountPerAddress: 1,
        publicMintPrice: 3 ether,
        publicStartTime: block.timestamp,
        publicEndTime: block.timestamp + 1000,
        whitelistStartTime: block.timestamp,
        whitelistEndTime: block.timestamp + 1000,
        presaleMaxSupply: config.presaleMaxSupply,
        presaleAmountPerWallet: config.presaleAmountPerWallet,
        presaleStartTime: config.presaleStartTime,
        presaleEndTime: config.presaleEndTime
      })
    );
    assertEq(erc721presale.getCollectionConfig().maxSupply, 100);
  }

  function testCannotSetConfigNotCreator() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x3E8;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
      name: name,
      symbol: symbol,
      fundsReceiver: creator,
      maxSupply: 10,
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
    ERC721Presale erc721presale = ERC721Presale(moonpierproxy.getCollectionData(id).collection);

    vm.startPrank(alice);
    vm.expectRevert(Errors.CreatorOnly.selector);
    erc721presale.setCollectionConfig(
      DataTypes.CollectionConfig({
        fundsReceiver: creator,
        maxSupply: 10,
        maxAmountPerAddress: 1,
        publicMintPrice: 3 ether,
        publicStartTime: block.timestamp,
        publicEndTime: block.timestamp + 1000,
        whitelistStartTime: block.timestamp,
        whitelistEndTime: block.timestamp + 1000,
        presaleMaxSupply: config.presaleMaxSupply,
        presaleAmountPerWallet: config.presaleAmountPerWallet,
        presaleStartTime: config.presaleStartTime,
        presaleEndTime: config.presaleEndTime
      })
    );
  }

  function testUpdateImpl() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x3E8;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
      name: name,
      symbol: symbol,
      fundsReceiver: creator,
      maxSupply: 10,
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
    ERC721Presale erc721presale = ERC721Presale(moonpierproxy.getCollectionData(id).collection);

    vm.startPrank(admin);
    erc721presale.upgradeTo(moonpierproxy.erc721implementation());
  }

  function testCannotUpdateImplNotAdmin() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x3E8;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
      name: name,
      symbol: symbol,
      fundsReceiver: creator,
      maxSupply: 10,
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
    ERC721Presale erc721presale = ERC721Presale(moonpierproxy.getCollectionData(id).collection);

    vm.expectRevert(Errors.AdminOnly.selector);
    erc721presale.upgradeTo(alice);
  }

  function testSupportsInterface() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x3E8;

    string memory name = "name";
    string memory symbol = "NM";

    DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
      name: name,
      symbol: symbol,
      fundsReceiver: creator,
      maxSupply: 10,
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
    ERC721Presale erc721presale = ERC721Presale(moonpierproxy.getCollectionData(id).collection);

    assertTrue(erc721presale.supportsInterface(type(IERC165Upgradeable).interfaceId));
  }
}
