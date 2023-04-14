// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import {ERC721Presale} from "../contracts/core/ERC721Presale.sol";
import {MoonFish} from "../contracts/core/MoonFish.sol";
import {MoonFishAddressProvider} from "../contracts/core/MoonFishAddressProvider.sol";
import {FeeManager} from "../contracts/core/FeeManager.sol";
import {MToken} from "../contracts/core/MToken.sol";
import {TokenIdentifiers} from "../contracts/core/TokenIdentifiers.sol";
import {WETHGateway} from "../contracts/core/WETHGateway.sol";
// import {WETH9Mocked} from "../contracts/mocks/WETH9Mocked.sol";
import {WETH9} from "../contracts/mocks/WETH9.sol";
import {ERC721PresaleProxy} from "../contracts/core/ERC721PresaleProxy.sol";
import {MoonFishProxy} from "../contracts/core/MoonFishProxy.sol";
import {MoonFishAddressProviderProxy} from "../contracts/core/MoonFishAddressProviderProxy.sol";

contract DeployScript is Script {
  function run() external {
    uint256 deployerPrivateKey = vm.envUint("SEPOLIA_MOONPIER_PRIVATE_KEY");
    address adminAddress = vm.addr(deployerPrivateKey);
    vm.startBroadcast(deployerPrivateKey);

    // deploy addres Provider
    MoonFishAddressProvider moonfishAddressProvider = new MoonFishAddressProvider(0);
    MoonFishAddressProvider moonfishAddressProviderProxy = MoonFishAddressProvider(
      address(new MoonFishAddressProviderProxy(address(moonfishAddressProvider), ""))
    );
    MoonFishAddressProvider(address(moonfishAddressProviderProxy)).initialize();

    // deploy erc721presale implementation
    ERC721Presale erc721Presale = new ERC721Presale(address(moonfishAddressProviderProxy));

    // deploy moonfish
    MoonFish moonfish = new MoonFish(address(erc721Presale));
    MoonFish moonfishproxy = MoonFish(address(new MoonFishProxy(address(moonfish), "")));
    moonfishproxy.initialize();
    moonfishproxy.setPresaleFee(1000);

    // set address provider
    FeeManager feeManager = new FeeManager(1000, adminAddress);
    moonfishAddressProviderProxy.setFeeManager(address(feeManager));
    moonfishAddressProviderProxy.setMoonFish(address(moonfishproxy));

    // add weth reserve, mToken and gateway
    WETH9 weth = new WETH9();
    MToken mtoken = new MToken(address(weth), address(moonfishproxy));
    moonfishproxy.addReserve(address(weth), address(mtoken));
    new WETHGateway(address(weth), address(moonfishproxy));

    vm.stopBroadcast();
  }
}
