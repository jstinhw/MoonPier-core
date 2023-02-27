// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IFeeManager {
  /**
   * @notice Emitted when a fee override is set
   * @param collection The address of the collection
   * @param amount The fee amount
   */
  event FeeOverrideSet(address indexed collection, uint256 indexed amount);

  /**
   * @notice Get the fee for a given collection
   * @param collection The address of the collection
   */
  function getFees(address collection) external view returns (address payable, uint256);

  /**
   * @notice Set the fee for a given collection
   * @param collection The address of the collection
   * @param amount The fee amount
   */
  function setFeeOverride(address collection, uint256 amount) external;
}
