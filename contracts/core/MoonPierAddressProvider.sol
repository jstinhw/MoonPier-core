// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {OwnableUpgradeable} from "openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {IMoonPierAddressProvider} from "../interfaces/IMoonPierAddressProvider.sol";

/**
 * @title MoonPierAddressProvider contract
 * @author MoonPier
 * @notice MoonPierAddressProvider is a contract that stores the addresses of the other MoonPier contracts
 */
contract MoonPierAddressProvider is UUPSUpgradeable, OwnableUpgradeable, IMoonPierAddressProvider {
  uint256 internal immutable _version;

  mapping(bytes32 => address) internal _addresses;
  bytes32 private constant MOON_PIER = "MOON_PIER";
  bytes32 private constant FEE_MANAGER = "FEE_MANAGER";

  constructor(uint256 version) initializer {
    _version = version;
  }

  function initialize() external initializer {
    __Ownable_init();
    __UUPSUpgradeable_init();
  }

  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

  function setMoonPier(address moonPier) external override onlyOwner {
    _addresses[MOON_PIER] = moonPier;
  }

  function setFeeManager(address feeManager) external override onlyOwner {
    _addresses[FEE_MANAGER] = feeManager;
  }

  function getMoonPier() external view override returns (address) {
    return _addresses[MOON_PIER];
  }

  function getFeeManager() external view override returns (address) {
    return _addresses[FEE_MANAGER];
  }
}
