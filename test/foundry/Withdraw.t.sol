// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {BaseSetup} from "./BaseSetup.t.sol";
import {WETHGateway} from "../../contracts/core/WETHGateway.sol";
import {DataTypes} from "../../contracts/libraries/DataTypes.sol";
import {IWETH} from "../../contracts/interfaces/IWETH.sol";
import {Errors} from "../../contracts/libraries/Errors.sol";

contract WithdrawTest is BaseSetup {
  uint256 public downpaymentWETH = 1000;

  function setUp() public virtual override {
    BaseSetup.setUp();
    moonfishproxy.addReserve(address(weth), address(mtoken));
    wethgateway = new WETHGateway(address(weth), address(moonfishproxy));
  }

  function testWithdrawDownPayment() public {
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

    vm.startPrank(creator);
    moonfishproxy.createCollection(address(weth), id, name, symbol, config);

    // withdraw
    mtoken.setApprovalForAll(address(wethgateway), true);
    uint256 beforeBalance = creator.balance;
    wethgateway.withdraw(id, downpayment);
    uint256 afterBalance = creator.balance;
    assertEq(afterBalance - beforeBalance, downpayment);
  }

  function testWithdrawPresale() public {
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
    vm.prank(alice);
    wethgateway.joinETH{value: joinAmount}(id);

    vm.prank(creator);
    moonfishproxy.createCollection(address(weth), id, name, symbol, config);

    // premint
    vm.startPrank(alice);
    mtoken.setApprovalForAll(address(wethgateway), true);
    wethgateway.premint(id, 1);
    vm.stopPrank();

    // withdraw
    vm.startPrank(creator);
    mtoken.setApprovalForAll(address(wethgateway), true);
    uint256 beforeBalance = creator.balance;
    wethgateway.withdraw(id, joinAmount);
    uint256 afterBalance = creator.balance;
    assertEq(afterBalance - beforeBalance, joinAmount);
  }

  function testWithdrawDownPaymentFromMoonFish() public {
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

    vm.startPrank(creator);
    moonfishproxy.createCollection(address(weth), id, name, symbol, config);

    // withdraw from MoonFish directly
    mtoken.setApprovalForAll(address(moonfishproxy), true);
    moonfishproxy.withdraw(creator, id, downpayment, creator);
    assertEq(IWETH(address(weth)).balanceOf(address(creator)), downpayment);
  }

  function testCannotWithdrawNonCreator() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 14) | 0x3E8;
    uint256 joinAmount = 1 ether;
    uint256 premintedAmount = (joinAmount * (10000 - downpaymentWETH)) / 10000;

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
    // join
    vm.prank(alice);
    wethgateway.joinETH{value: joinAmount}(id);

    // create
    vm.prank(creator);
    moonfishproxy.createCollection(address(weth), id, name, symbol, config);

    // withdraw from MoonFish directly
    vm.startPrank(alice);
    mtoken.setApprovalForAll(address(wethgateway), true);
    vm.expectRevert("Create: not creator");
    wethgateway.withdraw(id, premintedAmount);
  }

  function testShouldNotWithdrawFromMoonFish() public {
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

    // withdraw from MoonFish directly
    vm.startPrank(alice);

    mtoken.setApprovalForAll(address(moonfishproxy), true);
    vm.expectRevert("Create: not creator");
    moonfishproxy.withdraw(alice, id, downpayment, alice);
  }

  function testCanNotWithdrawCollectionNotExist() public {
    uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 14) | 0x3E8;
    uint256 joinAmount = 1 ether;
    uint256 premintedAmount = (joinAmount * (10000 - downpaymentWETH)) / 10000;

    vm.startPrank(alice);
    wethgateway.joinETH{value: joinAmount}(id);

    // withdraw from MoonFish directly
    mtoken.setApprovalForAll(address(moonfishproxy), true);
    vm.expectRevert(Errors.MoonFishCollectionNotExist.selector);
    moonfishproxy.withdraw(alice, id, premintedAmount, creator);
  }
}
