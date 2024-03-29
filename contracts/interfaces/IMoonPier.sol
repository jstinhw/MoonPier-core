// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {DataTypes} from "../libraries/DataTypes.sol";

interface IMoonPier {
  /**
   * @notice Add reserve
   * @param underlying The underlying asset address of reserve token
   * @param mToken The address of mToken
   */
  function addReserve(address underlying, address mToken) external;

  /**
   * @notice Set presale fee
   * @param fee The fee of presale
   */
  function setPresaleFee(uint256 fee) external;

  /**
   * @notice Join collection as premint token
   * @param reserve The address of reserve token
   * @param id ID of premint collection
   * @param amount The amount of underlying token
   */
  function join(address reserve, uint256 id, uint256 amount, address to) external;

  /**
   * @notice Leave collection and withdraw `amount` of underlying token
   * @param reserve The address of reserve token
   * @param id ID of premint collection
   * @param amount The amount of underlying token
   * @param to The address to send underlying token
   * @return The amount of underlying token
   */
  function leave(address reserve, uint256 id, uint256 amount, address to) external returns (uint256);

  /**
   * @notice Premint `amount` of collection
   * @param id ID of premint collection
   * @param amount The amount of preminted collection tokens
   * @param to The address of token receiver
   */
  function premint(uint256 id, uint256 amount, address to) external;

  /**
   * @notice Create collection by creator
   * @param reserve The address of reserve underlying token
   * @param id ID of premint collection
   * @param config The config of collection
   */
  function createCollection(address reserve, uint256 id, DataTypes.CreateCollectionParams calldata config) external;

  /**
   * @notice Get reserve count
   */
  function getReserveCount() external view returns (uint8);

  /**
   * @notice Get reserve underlying token address from id
   * @param id ID of reserve
   */
  function getReserveUnderlyingFromId(uint256 id) external view returns (address);

  /**
   * @notice Get reserve data
   * @param underlying The address of underlying token
   */
  function getReserveData(address underlying) external view returns (DataTypes.ReserveData memory);

  /**
   * @notice Get collection data
   * @param id ID of premint collection
   */
  function getCollectionData(uint256 id) external view returns (DataTypes.CollectionData memory);

  /**
   * @notice Get presale fee
   */
  function getPresaleFee() external view returns (uint256);
}
