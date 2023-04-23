// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IMoonPierAddressProvider {
  /**
   * @notice Set MoonPier address
   * @param moonPier MoonPier address
   */
  function setMoonPier(address moonPier) external;

  /**
   * @notice Set FeeManager address
   * @param feeManager FeeManager address
   */
  function setFeeManager(address feeManager) external;

  /**
   * @notice Get MoonPier address
   */
  function getMoonPier() external view returns (address);

  /**
   * @notice Get FeeManager address
   */
  function getFeeManager() external view returns (address);
}
