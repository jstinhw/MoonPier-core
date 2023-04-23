// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IWETHGateway {
  /**
   * @dev Joins a collection using native ETH
   * @param id ID of the collection
   */
  function joinETH(uint256 id) external payable;

  /**
   * @dev Leaves a collection and sends the native ETH to an address
   * @param id ID of the collection
   * @param amount The amount of underlying tokens to leave
   * @param to The address to send the underlying tokens to
   */
  function leaveETH(uint256 id, uint256 amount, address to) external;

  /**
   * @dev Premints a collection with mETH
   * @param id ID of the collection
   * @param amount The amount of preminted token
   */
  function premint(uint256 id, uint256 amount) external;
}
