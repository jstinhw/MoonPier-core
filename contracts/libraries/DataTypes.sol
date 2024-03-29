// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * @title DataTypes library
 * @author MoonPier
 * @notice A library that contains the data types used in the MoonPier protocol
 */
library DataTypes {
  struct ReserveData {
    address mToken;
    uint8 id;
  }

  struct CollectionData {
    address collection;
    address reserve;
    uint256 index;
    uint256 presalePrice;
  }

  struct CreateCollectionParams {
    string name;
    string symbol;
    address fundsReceiver;
    uint256 maxSupply;
    uint256 maxAmountPerAddress;
    uint256 publicMintPrice;
    uint256 publicStartTime;
    uint256 publicEndTime;
    uint256 whitelistStartTime;
    uint256 whitelistEndTime;
    uint256 presaleMaxSupply;
    uint256 presalePrice;
    uint256 presaleAmountPerWallet;
    uint256 presaleStartTime;
    uint256 presaleEndTime;
    string metadataUri;
  }

  struct CollectionConfig {
    address fundsReceiver;
    uint256 maxSupply;
    uint256 maxAmountPerAddress;
    uint256 publicMintPrice;
    uint256 publicStartTime;
    uint256 publicEndTime;
    uint256 whitelistStartTime;
    uint256 whitelistEndTime;
    uint256 presaleMaxSupply;
    uint256 presaleAmountPerWallet;
    uint256 presaleStartTime;
    uint256 presaleEndTime;
  }
}
