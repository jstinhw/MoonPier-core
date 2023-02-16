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
    address[] memory addresses = utils.createUsers(3);
    admin = msg.sender;
    creator = addresses[0];
    alice = addresses[1];
    bob = addresses[2];
    weth = new WETH9Mocked();

    // deploy Address Provider
    moonFishAddressProvider = new MoonFishAddressProvider(0);
    moonFishAddressProviderProxy =
      MoonFishAddressProvider(address(new MoonFishProxy(address(moonFishAddressProvider), "")));

    MoonFishAddressProvider(address(moonFishAddressProviderProxy)).initialize();

    feeManager = new FeeManager(1000, creator);
    erc721Presale = new ERC721Presale(address(moonFishAddressProviderProxy));
    moonfish = new MoonFish(address(erc721Presale));
    moonfishproxy = MoonFish(address(new MoonFishProxy(address(moonfish), "")));
    MoonFish(address(moonfishproxy)).initialize();
    mtoken = new MToken(address(weth), address(moonfishproxy));

    moonFishAddressProviderProxy.setMoonFish(address(moonfishproxy));
    moonFishAddressProviderProxy.setFeeManager(address(feeManager));

    // wethgateway = new WETHGateway(address(weth), address(moonfishproxy));

    // moonfishproxy.addReserve(address(weth), downpaymentWETH, address(mtoken));
  }
}
