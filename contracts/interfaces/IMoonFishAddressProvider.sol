// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IMoonFishAddressProvider {
  /**
   * @notice Set MoonFish address
   * @param moonFish MoonFish address
   */
  function setMoonFish(address moonFish) external;

  /**
   * @notice Set FeeManager address
   * @param feeManager FeeManager address
   */
  function setFeeManager(address feeManager) external;

  /**
   * @notice Get MoonFish address
   */
  function getMoonFish() external view returns (address);

  /**
   * @notice Get FeeManager address
   */
  function getFeeManager() external view returns (address);
}
