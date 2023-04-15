// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {DataTypes} from "../libraries/DataTypes.sol";
import {TokenIdentifiers} from "../core/TokenIdentifiers.sol";
import {IMToken} from "../interfaces/IMToken.sol";
import {IERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";
import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {ERC721Presale} from "../core/ERC721Presale.sol";
import {ERC721PresaleProxy} from "../core/ERC721PresaleProxy.sol";
import {ERC721Presale} from "../core/ERC721Presale.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {Errors} from "../libraries/Errors.sol";
import {Events} from "../libraries/Events.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

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
    DataTypes.CreateCollectionParams memory config,
    address feeTo,
    uint256 presaleFee,
    mapping(uint256 => DataTypes.CollectionData) storage collections,
    address mToken
  ) external onlyCreator(id, msg.sender) {
    require(collections[id].collection == address(0), "Create: collection exists");
    require(mToken != address(0), "Create: invalid reserve");

    ERC721PresaleProxy deployed = new ERC721PresaleProxy(implementation, "");
    ERC721Presale(address(deployed)).initialize({
      creator: msg.sender,
      name: config.name,
      symbol: config.symbol,
      metadataUri: config.metadataUri,
      collectionConfig: DataTypes.CollectionConfig({
        fundsReceiver: config.fundsReceiver,
        maxSupply: config.maxSupply,
        maxAmountPerAddress: config.maxAmountPerAddress,
        publicMintPrice: config.publicMintPrice,
        publicStartTime: config.publicStartTime,
        publicEndTime: config.publicEndTime,
        whitelistStartTime: config.whitelistStartTime,
        whitelistEndTime: config.whitelistEndTime,
        presaleMaxSupply: config.presaleMaxSupply,
        presaleAmountPerWallet: config.presaleAmountPerWallet,
        presaleStartTime: config.presaleStartTime,
        presaleEndTime: config.presaleEndTime
      })
    });

    collections[id] = DataTypes.CollectionData({
      collection: address(deployed),
      reserve: reserve,
      index: id,
      presalePrice: config.presalePrice
    });

    uint256 maxDownpayment = config.presalePrice * config.presaleMaxSupply;
    uint256 allDownpayment = IMToken(mToken).balanceOf(mToken, id);

    if (maxDownpayment > allDownpayment) {
      maxDownpayment = allDownpayment;
    }
    uint256 fee = (maxDownpayment * presaleFee) / 10000;

    IMToken(mToken).safeTransferFrom(mToken, address(this), id, maxDownpayment, "");
    IMToken(mToken).burn(address(this), id, maxDownpayment);
    IERC20(reserve).transferFrom(address(this), feeTo, fee);
    IERC20(reserve).transferFrom(address(this), msg.sender, maxDownpayment - fee);

    emit Events.CollectionCreated(reserve, msg.sender, id, address(deployed));
  }

  function premint(
    uint256 id,
    uint256 amount,
    address to,
    address feeTo,
    uint256 presaleFee,
    mapping(address => DataTypes.ReserveData) storage reserves,
    mapping(uint256 => DataTypes.CollectionData) storage collections
  ) external {
    DataTypes.CollectionData storage collectiondata = collections[id];
    if (collectiondata.collection == address(0)) {
      revert Errors.CollectionNotExist();
    }
    if (collectiondata.presalePrice == 0) {
      revert Errors.CollectionNotPresale();
    }

    uint256 downpaymentRate = id.tokenDownpayment();
    IMToken mtoken = IMToken(reserves[collectiondata.reserve].mToken);
    // uint256 balance = mtoken.balanceOf(msg.sender, id);
    // uint256 presalePrice = collectiondata.presalePrice;

    if (
      mtoken.balanceOf(msg.sender, id) < ((collectiondata.presalePrice * (10000 - downpaymentRate)) / 10000) * amount
    ) {
      revert Errors.PremintInsufficientBalance();
    }
    uint256 fee = (((collectiondata.presalePrice * (10000 - downpaymentRate)) / 10000) * amount * presaleFee) / 10000;
    mtoken.safeTransferFrom(msg.sender, feeTo, id, fee, "");
    mtoken.safeTransferFrom(
      msg.sender,
      id.tokenCreator(),
      id,
      ((collectiondata.presalePrice * (10000 - downpaymentRate)) / 10000) * amount - fee,
      ""
    );
    ERC721Presale(collectiondata.collection).presaleMint(to, amount);
    emit Events.CollectionPreminted(collectiondata.reserve, msg.sender, id, amount);
  }

  function _isCreator(uint256 _id, address _address) internal pure returns (bool) {
    return _address == _id.tokenCreator();
  }
}
