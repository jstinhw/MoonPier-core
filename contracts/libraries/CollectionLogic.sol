// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {DataTypes} from "../libraries/DataTypes.sol";
import {TokenIdentifiers} from "../core/TokenIdentifiers.sol";
import {IMToken} from "../interfaces/IMToken.sol";
import {IERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";
import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
// import {TestERC721} from "../test/TestERC721.sol";
import {ERC721Presale} from "../core/ERC721Presale.sol";
import {ERC721PresaleProxy} from "../core/ERC721PresaleProxy.sol";
import {ERC721Presale} from "../core/ERC721Presale.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {Errors} from "../libraries/Errors.sol";

import "forge-std/console2.sol";

library CollectionLogic {
  using TokenIdentifiers for uint256;

  modifier onlyCreator(uint256 id, address creator) {
    require(_isCreator(id, creator), "Create: not creator");
    _;
  }

  function create(
    address implementation,
    address reserve,
    uint256 id,
    string memory name,
    string memory symbol,
    DataTypes.CreateCollectionParams memory config,
    mapping(uint256 => DataTypes.CollectionData) storage collections,
    address mToken
  ) external onlyCreator(id, msg.sender) {
    require(collections[id].collection == address(0), "Create: collection exists");

    // TODO: deploy contract
    ERC721PresaleProxy deployed = new ERC721PresaleProxy(implementation, "");
    ERC721Presale(address(deployed)).initialize({
      admin: msg.sender,
      name: name,
      symbol: symbol,
      collectionConfig: DataTypes.CollectionConfig({
        fundsReceiver: config.fundsReceiver,
        maxSupply: config.maxSupply,
        maxAmountPerAddress: config.maxAmountPerAddress,
        publicMintPrice: config.publicMintPrice,
        publicStartTime: config.publicStartTime,
        publicEndTime: config.publicEndTime,
        whitelistStartTime: config.whitelistStartTime,
        whitelistEndTime: config.whitelistEndTime
      })
    });

    collections[id] = DataTypes.CollectionData({
      collection: address(deployed),
      reserve: reserve,
      index: id,
      presalePrice: config.presalePrice,
      presaleTotalSupply: 0,
      presaleMaxSupply: config.presaleMaxSupply,
      presaleAmountPerAddress: config.presaleAmountPerWallet,
      presaleStartTime: config.presaleStartTime,
      presaleEndTime: config.presaleEndTime
    });

    uint256 maxDownpayment = config.presalePrice * config.presaleMaxSupply;
    uint256 allDownpayment = IMToken(mToken).balanceOf(mToken, id);
    if (maxDownpayment > allDownpayment) {
      maxDownpayment = allDownpayment;
    }
    IMToken(mToken).safeTransferFrom(mToken, msg.sender, id, maxDownpayment, "");
  }

  function premint(
    uint256 id,
    uint256 amount,
    address to,
    mapping(address => DataTypes.ReserveData) storage reserves,
    mapping(uint256 => DataTypes.CollectionData) storage collections
  ) external {
    DataTypes.CollectionData storage collectiondata = collections[id];
    if (collectiondata.collection == address(0)) {
      revert Errors.MoonFishCollectionNotExist();
    }
    if (collectiondata.presaleTotalSupply + amount > collectiondata.presaleMaxSupply) {
      revert Errors.MoonFishExceedMaxSupply();
    }
    uint256 downpaymentRate = id.tokenDownpayment();
    // uint256 downpaymentRate = reserves[collectiondata.reserve].downpaymentRate;
    IMToken mtoken = IMToken(reserves[collectiondata.reserve].mToken);
    uint256 balance = mtoken.balanceOf(msg.sender, id);
    // uint256 presalePrice = ERC721Presale(collectiondata.collection).getPresalePrice();
    uint256 presalePrice = collectiondata.presalePrice;

    if (balance < ((presalePrice * (10000 - downpaymentRate)) / 10000) * amount) {
      revert Errors.MoonFishPremintInsufficientBalance();
    }
    collectiondata.presaleTotalSupply += amount;

    mtoken.safeTransferFrom(
      msg.sender,
      id.tokenCreator(),
      id,
      ((presalePrice * (10000 - downpaymentRate)) / 10000) * amount,
      ""
    );
    ERC721Presale(collectiondata.collection).presaleMint(to, amount);
  }

  function _isCreator(uint256 _id, address _address) internal pure returns (bool) {
    return _address == _id.tokenCreator();
  }
}
