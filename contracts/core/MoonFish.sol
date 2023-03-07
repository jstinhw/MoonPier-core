// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ReentrancyGuardUpgradeable} from "openzeppelin-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import {IERC1155ReceiverUpgradeable} from "openzeppelin-upgradeable/contracts/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import {ERC1155Upgradeable} from "openzeppelin-upgradeable/contracts/token/ERC1155/ERC1155Upgradeable.sol";
import {OwnableUpgradeable} from "openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

import {IMoonFish} from "../interfaces/IMoonFish.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {CollectionLogic} from "../libraries/CollectionLogic.sol";
import {JoinLogic} from "../libraries/JoinLogic.sol";
import {TokenIdentifiers} from "./TokenIdentifiers.sol";
import "forge-std/console2.sol";

/**
 * @title MoonFish contract
 * @author MoonPier
 * @notice MoonFish is a contract that allows users to join and leave preminted collections
 */
contract MoonFish is UUPSUpgradeable, IMoonFish, ReentrancyGuardUpgradeable, OwnableUpgradeable {
  using TokenIdentifiers for uint256;

  address public immutable erc721implementation;

  uint8 internal _reserveCount;
  mapping(address => DataTypes.ReserveData) internal _reserves;
  mapping(uint256 => address) internal _reservesList;

  mapping(uint256 => DataTypes.CollectionData) internal _collections;
  mapping(address => mapping(address => uint256)) internal _presaleMinted;

  constructor(address _erc721presaleimpl) initializer {
    erc721implementation = _erc721presaleimpl;
  }

  function initialize() external initializer {
    __Ownable_init();
    __UUPSUpgradeable_init();
    __ReentrancyGuard_init();
  }

  function addReserve(address underlyingAsset, address mToken) external override onlyOwner {
    _reserves[underlyingAsset] = (DataTypes.ReserveData({mToken: mToken, id: _reserveCount}));

    _reservesList[_reserveCount] = underlyingAsset;
    _reserveCount += 1;
  }

  function join(address reserve, uint256 id, uint256 amount, address to) external override nonReentrant {
    JoinLogic.join(reserve, id, amount, to, _reserves, _collections);
  }

  function leave(
    address reserve,
    uint256 id,
    uint256 amount,
    address to
  ) external override nonReentrant returns (uint256) {
    return JoinLogic.leave(reserve, id, amount, to, _reserves, _collections);
  }

  function premint(uint256 id, uint256 amount, address to) external override nonReentrant {
    CollectionLogic.premint(id, amount, to, _reserves, _collections);
  }

  function createCollection(
    address reserve,
    uint256 id,
    DataTypes.CreateCollectionParams calldata config
  ) external override nonReentrant {
    CollectionLogic.create(erc721implementation, reserve, id, config, _collections, _reserves[reserve].mToken);
  }

  function withdraw(
    address gateway,
    uint256 id,
    uint256 amount,
    address to
  ) external override nonReentrant returns (uint256) {
    return JoinLogic.withdraw(gateway, id, amount, to, _reserves, _collections);
  }

  function getReserveCount() external view override returns (uint8) {
    return _reserveCount;
  }

  function getReserveUnderlyingFromId(uint256 id) external view override returns (address) {
    return _reservesList[id];
  }

  function getReserveData(address underlying) external view override returns (DataTypes.ReserveData memory) {
    return _reserves[underlying];
  }

  function getCollectionData(uint256 id) external view override returns (DataTypes.CollectionData memory) {
    return _collections[id];
  }

  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
