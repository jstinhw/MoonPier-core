// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {DataTypes} from "../libraries/DataTypes.sol";

interface IERC721Presale {
  /**
   * @notice Set collection config
   * @param config Collection config
   */
  function setCollectionConfig(DataTypes.CollectionConfig calldata config) external;

  /**
   * @notice Set base URI
   * @param baseURI Base URI
   */
  function setBaseURI(string memory baseURI) external;

  /**
   * @notice Set merkle root
   * @param merkleRoot Merkle root
   */
  function setMerkleRoot(bytes32 merkleRoot) external;

  /**
   * @notice withdraw eth by admin
   */
  function withdraw() external;

  /**
   * @notice Mint tokens
   * @param amount Amount of tokens to mint
   */
  function mint(uint256 amount) external payable;

  /**
   * @notice Whitelist mint tokens
   * @param proof Merkle proof
   * @param amount Amount of tokens to mint
   * @param maxAmount Max amount of tokens to mint
   * @param pricePerToken Price per token
   */
  function whitelistMint(
    bytes32[] calldata proof,
    uint256 amount,
    uint256 maxAmount,
    uint256 pricePerToken
  ) external payable;

  /**
   * @notice Presale mint tokens
   * @param to Address to mint tokens to
   * @param amount Amount of tokens to mint
   */
  function presaleMint(address to, uint256 amount) external;

  /**
   * @notice Get collection config
   */
  function getCollectionConfig() external view returns (DataTypes.CollectionConfig memory);

  /**
   * @notice Get merkle root
   */
  function getMerkleRoot() external view returns (bytes32);

  /**
   * @notice Get whitelist minted amount
   * @param minter Address of minter
   */
  function getWhitelistMintedAmount(address minter) external view returns (uint256);

  /**
   * @notice Get presale minted amount
   * @param minter Address of minter
   */
  function getPresaleMintedAmount(address minter) external view returns (uint256);
}
