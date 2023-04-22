// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Test} from "forge-std/Test.sol";

import {ERC721Presale} from "../../contracts/core/ERC721Presale.sol";
import {FeeManager} from "../../contracts/core/FeeManager.sol";
import {MoonPier} from "../../contracts/core/MoonPier.sol";
import {MoonPierAddressProvider} from "../../contracts/core/MoonPierAddressProvider.sol";
import {MoonPierProxy} from "../../contracts/core/MoonPierProxy.sol";
import {MToken} from "../../contracts/core/MToken.sol";
import {WETHGateway} from "../../contracts/core/WETHGateway.sol";
import {WETH9Mocked} from "../../contracts/mocks/WETH9Mocked.sol";

import {Utils} from "./utils.sol";

contract BaseSetup is Test {
  address internal admin;
  address internal creator;
  address internal alice;
  address internal bob;
  address internal cindy;

  ERC721Presale internal erc721Presale;
  FeeManager internal feeManager;
  MoonPier internal moonpier;
  MoonPier internal moonpierproxy;
  MoonPierAddressProvider internal moonPierAddressProvider;
  MoonPierAddressProvider internal moonPierAddressProviderProxy;
  MToken internal mtoken;
  WETHGateway internal wethgateway;

  WETH9Mocked internal weth;

  function setUp() public virtual {
    Utils utils = new Utils();
    address[] memory addresses = utils.createUsers(4);
    admin = msg.sender;
    creator = addresses[0];
    alice = addresses[1];
    bob = addresses[2];
    cindy = addresses[3];
    weth = new WETH9Mocked();

    // deploy Address Provider
    vm.startPrank(admin);
    moonPierAddressProvider = new MoonPierAddressProvider(0);
    moonPierAddressProviderProxy = MoonPierAddressProvider(
      address(new MoonPierProxy(address(moonPierAddressProvider), ""))
    );
    MoonPierAddressProvider(address(moonPierAddressProviderProxy)).initialize();

    // deploy fee manager
    feeManager = new FeeManager(1000, admin);

    // deploy erc721presale implementation
    erc721Presale = new ERC721Presale(address(moonPierAddressProviderProxy));

    // deploy moonpier
    moonpier = new MoonPier(address(erc721Presale));
    moonpierproxy = MoonPier(address(new MoonPierProxy(address(moonpier), "")));
    MoonPier(address(moonpierproxy)).initialize();
    moonpierproxy.setPresaleFee(1000);

    // deploy mtoken
    mtoken = new MToken(address(weth), address(moonpierproxy));

    // address provider set moonPier and feeManager
    moonPierAddressProviderProxy.setMoonPier(address(moonpierproxy));
    moonPierAddressProviderProxy.setFeeManager(address(feeManager));
    vm.stopPrank();
  }

  function testSetup() public {
    setUp();
  }
}
