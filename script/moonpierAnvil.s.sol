// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import {ERC721Presale} from "../contracts/core/ERC721Presale.sol";
import {MoonPier} from "../contracts/core/MoonPier.sol";
import {MoonPierAddressProvider} from "../contracts/core/MoonPierAddressProvider.sol";
import {FeeManager} from "../contracts/core/FeeManager.sol";
import {MToken} from "../contracts/core/MToken.sol";
import {TokenIdentifiers} from "../contracts/core/TokenIdentifiers.sol";
import {WETHGateway} from "../contracts/core/WETHGateway.sol";
import {WETH9Mocked} from "../contracts/mocks/WETH9Mocked.sol";
import {ERC721PresaleProxy} from "../contracts/core/ERC721PresaleProxy.sol";
import {MoonPierProxy} from "../contracts/core/MoonPierProxy.sol";
import {MoonPierAddressProviderProxy} from "../contracts/core/MoonPierAddressProviderProxy.sol";

contract DeployScript is Script {
  function run() external {
    uint256 deployerPrivateKey = vm.envUint("ANVIL_PRIVATE_KEY");
    address adminAddress = vm.addr(deployerPrivateKey);
    vm.startBroadcast(deployerPrivateKey);

    // deploy addres Provider
    MoonPierAddressProvider moonpierAddressProvider = new MoonPierAddressProvider(0);
    MoonPierAddressProvider moonpierAddressProviderProxy = MoonPierAddressProvider(
      address(new MoonPierAddressProviderProxy(address(moonpierAddressProvider), ""))
    );
    moonpierAddressProviderProxy.initialize();

    // deploy erc721presale implementation
    ERC721Presale erc721Presale = new ERC721Presale(address(moonpierAddressProviderProxy));

    // deploy moonpier
    MoonPier moonpier = new MoonPier(address(erc721Presale));
    MoonPier moonpierproxy = MoonPier(address(new MoonPierProxy(address(moonpier), "")));
    moonpierproxy.initialize();
    moonpierproxy.setPresaleFee(1000);

    // set address provider
    FeeManager feeManager = new FeeManager(0, adminAddress);
    moonpierAddressProviderProxy.setFeeManager(address(feeManager));
    moonpierAddressProviderProxy.setMoonPier(address(moonpierproxy));

    // add weth reserve, mToken and gateway
    WETH9Mocked weth = new WETH9Mocked();
    MToken mtoken = new MToken(address(weth), address(moonpierproxy));
    moonpierproxy.addReserve(address(weth), address(mtoken));
    new WETHGateway(address(weth), address(moonpierproxy));

    vm.stopBroadcast();
  }
}
