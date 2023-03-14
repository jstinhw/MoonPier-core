// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Test} from "forge-std/Test.sol";

import {ERC721Presale} from "../../contracts/core/ERC721Presale.sol";
import {FeeManager} from "../../contracts/core/FeeManager.sol";
import {MoonFish} from "../../contracts/core/MoonFish.sol";
import {MoonFishAddressProvider} from "../../contracts/core/MoonFishAddressProvider.sol";
import {MoonFishProxy} from "../../contracts/core/MoonFishProxy.sol";
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
  MoonFish internal moonfish;
  MoonFish internal moonfishproxy;
  MoonFishAddressProvider internal moonFishAddressProvider;
  MoonFishAddressProvider internal moonFishAddressProviderProxy;
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
    moonFishAddressProvider = new MoonFishAddressProvider(0);
    moonFishAddressProviderProxy = MoonFishAddressProvider(
      address(new MoonFishProxy(address(moonFishAddressProvider), ""))
    );
    MoonFishAddressProvider(address(moonFishAddressProviderProxy)).initialize();

    // deploy fee manager
    feeManager = new FeeManager(1000, admin);

    // deploy erc721presale implementation
    erc721Presale = new ERC721Presale(address(moonFishAddressProviderProxy));

    // deploy moonfish
    moonfish = new MoonFish(address(erc721Presale));
    moonfishproxy = MoonFish(address(new MoonFishProxy(address(moonfish), "")));
    MoonFish(address(moonfishproxy)).initialize();
    moonfishproxy.setPresaleFee(1000);

    // deploy mtoken
    mtoken = new MToken(address(weth), address(moonfishproxy));

    // address provider set moonFish and feeManager
    moonFishAddressProviderProxy.setMoonFish(address(moonfishproxy));
    moonFishAddressProviderProxy.setFeeManager(address(feeManager));
    vm.stopPrank();
  }

  function testSetup() public {
    setUp();
  }
}
