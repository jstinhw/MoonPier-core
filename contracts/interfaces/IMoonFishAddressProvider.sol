// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IMoonFishAddressProvider {
  /**
   * @dev Set MoonFish address
   */
  function setMoonFish(address _moonFish) external;

  /**
   * @dev Set FeeManager address
   */
  function setFeeManager(address _feeManager) external;

  /**
   * @dev Get MoonFish address
   */
  function getMoonFish() external view returns (address);

  /**
   * @dev Get FeeManager address
   */
  function getFeeManager() external view returns (address);
}
