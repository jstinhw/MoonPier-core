// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library Events {
  /**
   * @notice Emitted when `user` join collection.
   * @param reserve The address of reserve token.
   * @param user The address join collection.
   * @param amount The amount of underlying token.
   * @param id ID of premint collection.
   */
  event CollectionJoined(address indexed reserve, address indexed user, uint256 amount, uint256 id);

  /**
   * @notice Emitted when `user` leave collection.
   * @param reserve The address of reserve token.
   * @param user The address leave collection.
   * @param amount The amount of underlying token.
   * @param id ID of premint collection.
   */
  event CollectionLeft(address indexed reserve, address indexed user, uint256 amount, uint256 id);

  /**
   * @dev Emitted when collection created.
   * @param reserve The address of reserve token.
   * @param creator The address of collection creator.
   * @param id ID of premint collection.
   * @param collection The address of created collection.
   */
  event CollectionCreated(address indexed reserve, address indexed creator, uint256 id, address collection);

  /**
   * @notice Emitted when `user` premint collection.
   * @param reserve The address of reserve.
   * @param user The address premint the collection.
   * @param id ID of preminted collection.
   * @param amount The amount of preminted collection tokens.
   */
  event CollectionPreminted(address indexed reserve, address indexed user, uint256 indexed id, uint256 amount);

  /**
   * @dev Emitted when `creator` withdraw reserve token.
   * @param gateway The address of gateway.
   * @param creator The address receiving withdrawed token.
   * @param id ID of the collection.
   * @param amount The amount of mToken to withdraw.
   */
  event CollectionWithdraw(address indexed gateway, address indexed creator, uint256 indexed id, uint256 amount);

  /**
   * @notice Emitted when a fee override is set.
   * @param collection The address of the collection.
   * @param amount The fee amount.
   */
  event FeeOverrideSet(address indexed collection, uint256 indexed amount);

  /**
   * @notice Emitted when a presale fee is set.
   * @param amount The fee amount.
   */
  event PresaleFeeSet(uint256 indexed amount);
}
