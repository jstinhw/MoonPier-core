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
    require(_isCreator(id, creator));
    _;
  }

  function create(
    address implementation,
    uint256 id,
    address reserve,
    DataTypes.CollectionConfig memory config,
    mapping(uint256 => DataTypes.CollectionData) storage collections,
    address mToken
  ) external onlyCreator(id, msg.sender) {
    require(collections[id].collection == address(0));

    // TODO: deploy contract
    ERC721PresaleProxy deployed = new ERC721PresaleProxy(implementation, "");
    ERC721Presale(address(deployed)).initialize({
      _admin: msg.sender,
      _name: "Test",
      _symbol: "TEST",
      _collectionConfig: config
    });

    collections[id] = DataTypes.CollectionData({
      collection: address(deployed),
      reserve: reserve,
      index: id,
      premintedPrice: config.publicMintPrice,
      premintedTotalSupply: 0,
      premintedMaxSupply: config.presaleMaxSupply,
      premintedAmountPerAddress: config.presaleAmountPerWallet
    });

    uint256 maxDownpayment = config.presaleMintPrice * config.presaleMaxSupply;
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
    uint256 downpaymentRate = reserves[collectiondata.reserve].downpaymentRate;
    address mtoken = reserves[collectiondata.reserve].mToken;

    if (collectiondata.collection == address(0)) {
      revert Errors.CollectionNotExist();
    }

    uint256 premintPrice = ERC721Presale(collectiondata.collection).getPresalePrice();

    IMToken(mtoken).safeTransferFrom(
      msg.sender,
      id.tokenCreator(),
      id,
      ((premintPrice * (100 - downpaymentRate)) / 100) * amount,
      ""
    );
    ERC721Presale(collectiondata.collection).presaleMint(to, amount);
    collectiondata.premintedTotalSupply += amount;
  }

  function _isCreator(uint256 _id, address _address) internal pure returns (bool) {
    return _address == _id.tokenCreator();
  }
}
