// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {DataTypes} from "../libraries/DataTypes.sol";

interface IERC721Presale {
  function mint(uint256 amount) external payable;

  function whitelistMint(
    bytes32[] calldata _proof,
    uint256 _amount,
    uint256 _maxAmount,
    uint256 _pricePerToken
  ) external payable;

  function presaleMint(address to, uint256 amount) external;

  function setBaseURI(string memory baseURI) external;

  function setMerkleRoot(bytes32 merkleRoot) external;

  function setCollectionConfig(DataTypes.CollectionConfig calldata config) external;

  function withdraw() external;

  function getConfig() external view returns (DataTypes.CollectionConfig memory);

  function getPresalePrice() external view returns (uint256);
}
