// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {DataTypes} from "../libraries/DataTypes.sol";

interface IMoonFish {
  /**
   * @dev Emitted on join()
   * @param user The address calling join()
   * @param reserve The address of reserve token
   * @param amount The amount of underlying token
   * @param id ID of premint collection
   */
  event Join(address indexed user, address indexed reserve, uint256 amount, uint256 id);

  /**
   * @dev Emitted on leave()
   * @param user The address calling leave()
   * @param reserve The address of reserve token
   * @param amount The amount of underlying token
   * @param id ID of premint collection
   * @param to The address to send underlying token
   */
  event Leave(address indexed user, address indexed reserve, uint256 amount, uint256 id, address indexed to);

  /**
   * @dev Emitted on premint()
   * @param user The address calling premint()
   * @param id ID of preminted collection
   * @param amount The amount of preminted collection tokens
   * @param collection The address of preminted collection
   */
  event Premint(address user, uint256 indexed id, uint256 amount, address collection);

  /**
   * @dev Join collection as premint token
   * @param reserve The address of reserve token
   * @param amount The amount of underlying token
   * @param id ID of premint collection
   */
  function join(address reserve, uint256 amount, uint256 id, address to) external;

  /**
   * @dev Leave collection and withdraw `amount` of underlying token
   * @param reserve The address of reserve token
   * @param amount The amount of underlying token
   * @param id ID of premint collection
   * @param to The address to send underlying token
   */
  function leave(address reserve, uint256 amount, uint256 id, address to) external;

  /**
   * @dev Premint `amount` of collection
   * @param id ID of premint collection
   * @param amount The amount of preminted collection tokens
   */
  function premint(uint256 id, uint256 amount) external;

  /**
   * @dev Create collection by creator
   * @param id ID of premint collection
   * @param reserve The address of reserve underlying token
   * @param config The config of collection
   */
  function createCollection(uint256 id, address reserve, DataTypes.CollectionConfig calldata config) external;

  function getReserveData(address underlying) external view returns (DataTypes.ReserveData memory);
}
