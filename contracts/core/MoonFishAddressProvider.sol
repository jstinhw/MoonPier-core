// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {OwnableUpgradeable} from "openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

contract MoonFishAddressProvider is UUPSUpgradeable, OwnableUpgradeable {
  uint256 private immutable version;

  mapping(bytes32 => address) private addresses;
  bytes32 private constant MOON_FISH = "MOONFISH";
  bytes32 private constant FEE_MANAGER = "FEE_MANAGER";

  constructor(uint256 _version) initializer {
    version = _version;
  }

  function initialize() external initializer {
    __Ownable_init();
    __UUPSUpgradeable_init();
  }

  function _authorizeUpgrade(address _newImplementation) internal override onlyOwner {}

  function setMoonFish(address _moonFish) external {
    addresses[MOON_FISH] = _moonFish;
  }

  function setFeeManager(address _feeManager) external {
    addresses[FEE_MANAGER] = _feeManager;
  }

  function getMoonFish() external view returns (address) {
    return addresses[MOON_FISH];
  }

  function getFeeManager() external view returns (address) {
    return addresses[FEE_MANAGER];
  }
}
