// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Test} from "forge-std/Test.sol";
import "forge-std/console2.sol";
import {MToken} from "../../contracts/core/MToken.sol";
import {MoonFish} from "../../contracts/core/MoonFish.sol";
import {WETHGateway} from "../../contracts/core/WETHGateway.sol";
import {WETH9Mocked} from "../../contracts/test/WETH9Mocked.sol";
import {Utils} from "./utils.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {FeeManager} from "../../contracts/core/FeeManager.sol";
import {ERC721Presale} from "../../contracts/core/ERC721Presale.sol";
import {DataTypes} from "../../contracts/libraries/DataTypes.sol";
import {MoonFishProxy} from "../../contracts/core/MoonFishProxy.sol";

contract TestWETHGateway is Test {
  address joiner;
  address creator;
  uint256 constant downpaymentWETH = 10;

  FeeManager feeManager;
  ERC721Presale erc721Presale;

  MoonFish moonfishproxy;
  MoonFish moonfish;
  WETHGateway wethgateway;
  WETH9Mocked weth;
  MToken mtoken;

  function setUp() public {
    Utils utils = new Utils();
    address[] memory addresses = utils.createUsers(2);
    creator = msg.sender;
    joiner = addresses[0];

    weth = new WETH9Mocked();
    moonfish = new MoonFish();
    moonfishproxy = MoonFish(address(new MoonFishProxy(address(moonfish), "")));
    MoonFish(address(moonfishproxy)).initialize();

    feeManager = new FeeManager(1000, creator);
    erc721Presale = new ERC721Presale(address(moonfishproxy), address(feeManager));
    moonfishproxy.setERC721Implementation(address(erc721Presale));

    mtoken = new MToken(address(weth), address(moonfishproxy));

    moonfishproxy.addReserve(address(weth), downpaymentWETH, address(mtoken));
    wethgateway = new WETHGateway(address(weth), address(moonfishproxy));
  }

  function testjoinETH() public {
    uint256 id = 1;
    uint256 amount = 10 ether;

    uint256 premintedAmount = amount * (100 - downpaymentWETH) / 100;

    // join with id 1 and 100 eth
    vm.prank(joiner);
    wethgateway.joinETH{value: amount}(id);
    assertEq(weth.balanceOf(address(mtoken)), amount);
    assertEq(mtoken.balanceOf(joiner, id), premintedAmount);
  }

  function testleaveETH() public {
    // join with id 1 and 100 eth
    uint256 id = 1;
    uint256 amount = 10 ether;
    uint256 premintedAmount = amount * (100 - downpaymentWETH) / 100;

    vm.prank(joiner);
    wethgateway.joinETH{value: amount}(id);

    // leave before creator create collection
    vm.prank(joiner);
    mtoken.setApprovalForAll(address(wethgateway), true);
    uint256 ethBefore = address(joiner).balance;
    vm.prank(joiner);
    wethgateway.leaveETH(id, premintedAmount, joiner);
    uint256 ethAfter = address(joiner).balance;

    assertEq(ethAfter - ethBefore, amount);
    assertEq(mtoken.balanceOf(joiner, id), 0);
  }

  function testFailCreateCollection() public {
    uint256 id = 1;
    uint256 joinamount = 1 ether;

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
    vm.prank(joiner);
    wethgateway.joinETH{value: joinamount}(id);
    moonfish.createCollection(id, address(weth), config);
  }

  function testCreateCollection() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x01;
    uint256 joinAmount = 1 ether;

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

    uint256 premintedAmount = joinAmount * (100 - downpaymentWETH) / 100;
    uint256 downpayment = joinAmount - premintedAmount;

    vm.prank(joiner);
    wethgateway.joinETH{value: joinAmount}(id);
    vm.prank(creator);
    moonfishproxy.createCollection(id, address(weth), config);
    assertEq(mtoken.balanceOf(creator, id), downpayment);
  }

  function testJoinerLeaveAfterCollectionCreated() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x01;

    uint256 joinAmount = 1 ether;

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

    uint256 premintedAmount = joinAmount * (100 - downpaymentWETH) / 100;

    vm.prank(joiner);
    wethgateway.joinETH{value: joinAmount}(id);
    vm.prank(creator);
    moonfishproxy.createCollection(id, address(weth), config);
    vm.prank(joiner);
    mtoken.setApprovalForAll(address(wethgateway), true);

    uint256 ethBefore = address(joiner).balance;
    vm.prank(joiner);
    wethgateway.leaveETH(id, premintedAmount, joiner);
    uint256 ethAfter = address(joiner).balance;

    assertEq(ethAfter - ethBefore, premintedAmount);
    assertEq(mtoken.balanceOf(joiner, id), 0);
  }

  function testPremint() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 64) | 0x01;

    uint256 joinAmount = 1 ether;

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

    vm.prank(joiner);
    wethgateway.joinETH{value: joinAmount}(id);
    vm.prank(creator);
    moonfishproxy.createCollection(id, address(weth), config);
    vm.prank(joiner);
    mtoken.setApprovalForAll(address(moonfishproxy), true);
    vm.prank(joiner);
    moonfishproxy.premint(id, 1);
    assertEq(mtoken.balanceOf(creator, id), joinAmount);
    assertEq(mtoken.balanceOf(joiner, id), 0);
    assertEq(IERC721(moonfishproxy.getCollectiondata(id).collection).balanceOf(joiner), 1);
    assertEq(IERC721(moonfishproxy.getCollectiondata(id).collection).ownerOf(0), joiner);
  }
}
