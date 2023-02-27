// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {OwnableUpgradeable} from "openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {IMoonFishAddressProvider} from "../interfaces/IMoonFishAddressProvider.sol";

/**
 * @title MoonFishAddressProvider contract
 * @author MoonPier
 * @notice MoonFishAddressProvider is a contract that stores the addresses of the other MoonFish contracts
 */
contract MoonFishAddressProvider is UUPSUpgradeable, OwnableUpgradeable, IMoonFishAddressProvider {
  uint256 internal immutable _version;

  mapping(bytes32 => address) internal _addresses;
  bytes32 private constant MOON_FISH = "MOON_FISH";
  bytes32 private constant FEE_MANAGER = "FEE_MANAGER";

  constructor(uint256 version) initializer {
    _version = version;
  }

  function initialize() external initializer {
    __Ownable_init();
    __UUPSUpgradeable_init();
  }

  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

  function setMoonFish(address moonFish) external override onlyOwner {
    _addresses[MOON_FISH] = moonFish;
  }

  function setFeeManager(address feeManager) external override onlyOwner {
    _addresses[FEE_MANAGER] = feeManager;
  }

  function getMoonFish() external view override returns (address) {
    return _addresses[MOON_FISH];
  }

  function getFeeManager() external view override returns (address) {
    return _addresses[FEE_MANAGER];
  }
}
