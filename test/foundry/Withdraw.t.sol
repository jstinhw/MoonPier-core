// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;

// import {BaseSetup} from "./BaseSetup.t.sol";
// import {WETHGateway} from "../../contracts/core/WETHGateway.sol";
// import {DataTypes} from "../../contracts/libraries/DataTypes.sol";
// import {IWETH} from "../../contracts/interfaces/IWETH.sol";
// import {Errors} from "../../contracts/libraries/Errors.sol";

// contract WithdrawTest is BaseSetup {
//   uint256 public downpaymentWETH = 1000;

//   function setUp() public virtual override {
//     BaseSetup.setUp();
//     vm.startPrank(admin);
//     moonpierproxy.addReserve(address(weth), address(mtoken));
//     wethgateway = new WETHGateway(address(weth), address(moonpierproxy));
//     vm.stopPrank();
//   }

//   // function testWithdrawDownPayment() public {
//   //   uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 16) | 0x3E8;
//   //   uint256 joinAmount = 1 ether;
//   //   uint256 premintedAmount = (joinAmount * (10000 - downpaymentWETH)) / 10000;
//   //   uint256 downpayment = joinAmount - premintedAmount;

//   //   string memory name = "name";
//   //   string memory symbol = "NM";
//   //   DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
//   //     name: name,
//   //     symbol: symbol,
//   //     fundsReceiver: creator,
//   //     maxSupply: 100,
//   //     maxAmountPerAddress: 1,
//   //     publicMintPrice: 3 ether,
//   //     publicStartTime: block.timestamp,
//   //     publicEndTime: block.timestamp + 1000,
//   //     whitelistStartTime: block.timestamp,
//   //     whitelistEndTime: block.timestamp + 1000,
//   //     presaleMaxSupply: 10,
//   //     presalePrice: 1 ether,
//   //     presaleAmountPerWallet: 1,
//   //     presaleStartTime: block.timestamp,
//   //     presaleEndTime: block.timestamp + 1000
//   //   });
//   //   vm.prank(alice);
//   //   wethgateway.joinETH{value: joinAmount}(id);

//   //   vm.startPrank(creator);
//   //   moonpierproxy.createCollection(address(weth), id, config);
//   //   uint256 expectedWithdrawAmount = (downpayment * 1000) / 10000;

//   //   // withdraw
//   //   mtoken.setApprovalForAll(address(wethgateway), true);
//   //   uint256 beforeBalance = creator.balance;
//   //   wethgateway.withdraw(id, expectedWithdrawAmount);
//   //   uint256 afterBalance = creator.balance;
//   //   assertEq(afterBalance - beforeBalance, expectedWithdrawAmount);
//   // }

//   function testWithdrawPresale() public {
//     uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 16) | 0x3E8;
//     uint256 joinAmount = 1 ether;

//     string memory name = "name";
//     string memory symbol = "NM";
//     DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
//       name: name,
//       symbol: symbol,
//       fundsReceiver: creator,
//       maxSupply: 100,
//       maxAmountPerAddress: 1,
//       publicMintPrice: 3 ether,
//       publicStartTime: block.timestamp,
//       publicEndTime: block.timestamp + 1000,
//       whitelistStartTime: block.timestamp,
//       whitelistEndTime: block.timestamp + 1000,
//       presaleMaxSupply: 10,
//       presalePrice: 1 ether,
//       presaleAmountPerWallet: 1,
//       presaleStartTime: block.timestamp,
//       presaleEndTime: block.timestamp + 1000,
//       metadataUri: "https://moonpier.art/"
//     });
//     vm.prank(alice);
//     wethgateway.joinETH{value: joinAmount}(id);

//     vm.prank(creator);
//     moonpierproxy.createCollection(address(weth), id, config);

//     // premint
//     vm.startPrank(alice);
//     mtoken.setApprovalForAll(address(wethgateway), true);
//     wethgateway.premint(id, 1);
//     vm.stopPrank();

//     uint256 expectedWithdrawAmount = (joinAmount * 1000) / 10000;

//     // withdraw
//     vm.startPrank(creator);
//     mtoken.setApprovalForAll(address(wethgateway), true);
//     uint256 beforeBalance = creator.balance;
//     wethgateway.withdraw(id, expectedWithdrawAmount);
//     uint256 afterBalance = creator.balance;
//     assertEq(afterBalance - beforeBalance, expectedWithdrawAmount);
//   }

//   // function testWithdrawDownPaymentFromMoonPier() public {
//   //   uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 16) | 0x3E8;
//   //   uint256 joinAmount = 1 ether;
//   //   uint256 premintedAmount = (joinAmount * (10000 - downpaymentWETH)) / 10000;
//   //   uint256 downpayment = joinAmount - premintedAmount;

//   //   string memory name = "name";
//   //   string memory symbol = "NM";
//   //   DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
//   //     name: name,
//   //     symbol: symbol,
//   //     fundsReceiver: creator,
//   //     maxSupply: 100,
//   //     maxAmountPerAddress: 1,
//   //     publicMintPrice: 3 ether,
//   //     publicStartTime: block.timestamp,
//   //     publicEndTime: block.timestamp + 1000,
//   //     whitelistStartTime: block.timestamp,
//   //     whitelistEndTime: block.timestamp + 1000,
//   //     presaleMaxSupply: 10,
//   //     presalePrice: 1 ether,
//   //     presaleAmountPerWallet: 1,
//   //     presaleStartTime: block.timestamp,
//   //     presaleEndTime: block.timestamp + 1000
//   //   });
//   //   vm.prank(alice);
//   //   wethgateway.joinETH{value: joinAmount}(id);

//   //   vm.startPrank(creator);
//   //   moonpierproxy.createCollection(address(weth), id, config);
//   //   uint256 expectedWithdrawAmount = (downpayment * 1000) / 10000;

//   //   withdraw from MoonPier directly
//   //   mtoken.setApprovalForAll(address(moonpierproxy), true);
//   //   moonpierproxy.withdraw(creator, id, expectedWithdrawAmount, creator);
//   //   assertEq(IWETH(address(weth)).balanceOf(address(creator)), expectedWithdrawAmount);
//   // }

//   function testCannotWithdrawNonCreator() public {
//     uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 16) | 0x3E8;
//     uint256 joinAmount = 1 ether;
//     uint256 premintedAmount = (joinAmount * (10000 - downpaymentWETH)) / 10000;

//     string memory name = "name";
//     string memory symbol = "NM";
//     DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
//       name: name,
//       symbol: symbol,
//       fundsReceiver: creator,
//       maxSupply: 100,
//       maxAmountPerAddress: 1,
//       publicMintPrice: 3 ether,
//       publicStartTime: block.timestamp,
//       publicEndTime: block.timestamp + 1000,
//       whitelistStartTime: block.timestamp,
//       whitelistEndTime: block.timestamp + 1000,
//       presaleMaxSupply: 10,
//       presalePrice: 1 ether,
//       presaleAmountPerWallet: 1,
//       presaleStartTime: block.timestamp,
//       presaleEndTime: block.timestamp + 1000,
//       metadataUri: "https://moonpier.art/"
//     });
//     // join
//     vm.prank(alice);
//     wethgateway.joinETH{value: joinAmount}(id);

//     // create
//     vm.prank(creator);
//     moonpierproxy.createCollection(address(weth), id, config);

//     // withdraw from MoonPier directly
//     vm.startPrank(alice);
//     mtoken.setApprovalForAll(address(wethgateway), true);
//     vm.expectRevert("Create: not creator");
//     wethgateway.withdraw(id, premintedAmount);
//   }

//   function testShouldNotWithdrawFromMoonPier() public {
//     uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 16) | 0x3E8;
//     uint256 joinAmount = 1 ether;
//     uint256 premintedAmount = (joinAmount * (10000 - downpaymentWETH)) / 10000;
//     uint256 downpayment = joinAmount - premintedAmount;

//     string memory name = "name";
//     string memory symbol = "NM";
//     DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
//       name: name,
//       symbol: symbol,
//       fundsReceiver: creator,
//       maxSupply: 100,
//       maxAmountPerAddress: 1,
//       publicMintPrice: 3 ether,
//       publicStartTime: block.timestamp,
//       publicEndTime: block.timestamp + 1000,
//       whitelistStartTime: block.timestamp,
//       whitelistEndTime: block.timestamp + 1000,
//       presaleMaxSupply: 10,
//       presalePrice: 1 ether,
//       presaleAmountPerWallet: 1,
//       presaleStartTime: block.timestamp,
//       presaleEndTime: block.timestamp + 1000,
//       metadataUri: "https://moonpier.art/"
//     });
//     vm.prank(alice);
//     wethgateway.joinETH{value: joinAmount}(id);

//     vm.prank(creator);
//     moonpierproxy.createCollection(address(weth), id, config);

//     // withdraw from MoonPier directly
//     vm.startPrank(alice);

//     mtoken.setApprovalForAll(address(moonpierproxy), true);
//     vm.expectRevert("Create: not creator");
//     moonpierproxy.withdraw(alice, id, downpayment, alice);
//   }

//   function testCanNotWithdrawCollectionNotExist() public {
//     uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 16) | 0x3E8;
//     uint256 joinAmount = 1 ether;
//     uint256 premintedAmount = (joinAmount * (10000 - downpaymentWETH)) / 10000;

//     vm.startPrank(alice);
//     wethgateway.joinETH{value: joinAmount}(id);

//     // withdraw from MoonPier directly
//     mtoken.setApprovalForAll(address(moonpierproxy), true);
//     vm.expectRevert(Errors.CollectionNotExist.selector);
//     moonpierproxy.withdraw(alice, id, premintedAmount, creator);
//   }

//   function testCannotWithdrawZeroAmount() public {
//     uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 16) | 0x3E8;
//     uint256 joinAmount = 1 ether;

//     string memory name = "name";
//     string memory symbol = "NM";
//     DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
//       name: name,
//       symbol: symbol,
//       fundsReceiver: creator,
//       maxSupply: 100,
//       maxAmountPerAddress: 1,
//       publicMintPrice: 3 ether,
//       publicStartTime: block.timestamp,
//       publicEndTime: block.timestamp + 1000,
//       whitelistStartTime: block.timestamp,
//       whitelistEndTime: block.timestamp + 1000,
//       presaleMaxSupply: 10,
//       presalePrice: 1 ether,
//       presaleAmountPerWallet: 1,
//       presaleStartTime: block.timestamp,
//       presaleEndTime: block.timestamp + 1000,
//       metadataUri: "https://moonpier.art/"
//     });
//     vm.prank(alice);
//     wethgateway.joinETH{value: joinAmount}(id);

//     vm.startPrank(creator);
//     moonpierproxy.createCollection(address(weth), id, config);

//     // withdraw
//     mtoken.setApprovalForAll(address(moonpierproxy), true);
//     vm.expectRevert("Withdraw: amount cannot be zero");
//     moonpierproxy.withdraw(address(wethgateway), id, 0, creator);
//   }

//   function testCannotWithdrawInsufficientAmount() public {
//     uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 16) | 0x3E8;
//     uint256 joinAmount = 1 ether;

//     string memory name = "name";
//     string memory symbol = "NM";
//     DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
//       name: name,
//       symbol: symbol,
//       fundsReceiver: creator,
//       maxSupply: 100,
//       maxAmountPerAddress: 1,
//       publicMintPrice: 3 ether,
//       publicStartTime: block.timestamp,
//       publicEndTime: block.timestamp + 1000,
//       whitelistStartTime: block.timestamp,
//       whitelistEndTime: block.timestamp + 1000,
//       presaleMaxSupply: 10,
//       presalePrice: 1 ether,
//       presaleAmountPerWallet: 1,
//       presaleStartTime: block.timestamp,
//       presaleEndTime: block.timestamp + 1000,
//       metadataUri: "https://moonpier.art/"
//     });
//     vm.prank(alice);
//     wethgateway.joinETH{value: joinAmount}(id);

//     vm.startPrank(creator);
//     moonpierproxy.createCollection(address(weth), id, config);

//     // withdraw
//     mtoken.setApprovalForAll(address(moonpierproxy), true);
//     vm.expectRevert(Errors.WithdrawInsufficientBalance.selector);
//     moonpierproxy.withdraw(address(wethgateway), id, joinAmount, creator);
//   }

//   function testCannotWithdrawGatewayInsufficientAmount() public {
//     uint256 id = (uint256(uint160(creator)) << 96) | (0x0 << 16) | 0x3E8;
//     uint256 joinAmount = 1 ether;

//     string memory name = "name";
//     string memory symbol = "NM";
//     DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
//       name: name,
//       symbol: symbol,
//       fundsReceiver: creator,
//       maxSupply: 100,
//       maxAmountPerAddress: 1,
//       publicMintPrice: 3 ether,
//       publicStartTime: block.timestamp,
//       publicEndTime: block.timestamp + 1000,
//       whitelistStartTime: block.timestamp,
//       whitelistEndTime: block.timestamp + 1000,
//       presaleMaxSupply: 10,
//       presalePrice: 1 ether,
//       presaleAmountPerWallet: 1,
//       presaleStartTime: block.timestamp,
//       presaleEndTime: block.timestamp + 1000,
//       metadataUri: "https://moonpier.art/"
//     });
//     vm.prank(alice);
//     wethgateway.joinETH{value: joinAmount}(id);

//     vm.startPrank(creator);
//     moonpierproxy.createCollection(address(weth), id, config);

//     // withdraw
//     mtoken.setApprovalForAll(address(wethgateway), true);
//     vm.expectRevert(Errors.GatewayWithdrawInsufficientBalance.selector);
//     wethgateway.withdraw(id, joinAmount);
//   }

//   // function testCannotWithdrawNonReceiveTo() public {
//   //   uint256 id = (uint256(uint160(address(mtoken))) << 96) | (0x0 << 14) | 0x3E8;
//   //   uint256 joinAmount = 1 ether;
//   //   uint256 premintedAmount = (joinAmount * (10000 - downpaymentWETH)) / 10000;
//   //   uint256 downpayment = joinAmount - premintedAmount;

//   //   string memory name = "name";
//   //   string memory symbol = "NM";
//   //   DataTypes.CreateCollectionParams memory config = DataTypes.CreateCollectionParams({
//   //     name: name,
//   //     symbol: symbol,
//   //     fundsReceiver: creator,
//   //     maxSupply: 100,
//   //     maxAmountPerAddress: 1,
//   //     publicMintPrice: 3 ether,
//   //     publicStartTime: block.timestamp,
//   //     publicEndTime: block.timestamp + 1000,
//   //     whitelistStartTime: block.timestamp,
//   //     whitelistEndTime: block.timestamp + 1000,
//   //     presaleMaxSupply: 10,
//   //     presalePrice: 1 ether,
//   //     presaleAmountPerWallet: 1,
//   //     presaleStartTime: block.timestamp,
//   //     presaleEndTime: block.timestamp + 1000
//   //   });
//   //   vm.prank(alice);
//   //   wethgateway.joinETH{value: joinAmount}(id);
//   //   uint256 expectedWithdrawAmount = (downpayment * 1000) / 10000;

//   //   // withdraw
//   //   vm.startPrank(address(mtoken));
//   //   moonpierproxy.createCollection(address(weth), id, config);
//   //   mtoken.setApprovalForAll(address(wethgateway), true);
//   //   vm.expectRevert("Transfer failed.");
//   //   wethgateway.withdraw(id, expectedWithdrawAmount);
//   // }
// }
