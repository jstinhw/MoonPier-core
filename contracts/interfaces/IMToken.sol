// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";

interface IMToken is IERC1155 {
  /**
   * @dev Mints `amount` mtokens to 'to'
   * @param to The address to mint to
   * @param id The id of the token to mint
   * @param amount The amount of tokens to mint
   */
  function mint(address to, uint256 id, uint256 amount) external;

  /**
   * @dev Burns `amount` mtokens from 'from'
   * @param from The address to burn from
   * @param id The id of the token to burn
   * @param amount The amount of tokens to burn
   */
  function burn(address from, uint256 id, uint256 amount) external;

  /**
   * @dev Returns the underlying asset address
   */
  function getUnderlyingAsset() external view returns (address);
}
