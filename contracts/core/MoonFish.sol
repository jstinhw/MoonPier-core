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
  mapping(address => DataTypes.ReserveData) internal reserves;
  mapping(uint256 => DataTypes.CollectionData) internal collections;

  mapping(uint256 => address) reservesList;
  uint8 internal reserveCount;

  constructor(address _erc721presaleimpl) initializer {
    erc721implementation = _erc721presaleimpl;
  }

  function initialize() external initializer {
    __Ownable_init();
    __UUPSUpgradeable_init();
  }

  function _authorizeUpgrade(address _newImplementation) internal override onlyOwner {}

  function addReserve(address _reserve, uint256 _downpaymentRate, address _mToken) external onlyOwner {
    require(_downpaymentRate < 100);
    reserves[_reserve] = (
      DataTypes.ReserveData({downpaymentRate: _downpaymentRate, mToken: _mToken, id: reserveCount})
    );

    reservesList[reserveCount] = _reserve;
    reserveCount += 1;
  }

  function join(address reserve, uint256 amount, uint256 id, address to) external override nonReentrant {
    JoinLogic.join(reserve, amount, id, to, reserves, collections);
  }

  function leave(
    address reserve,
    uint256 amount,
    uint256 id,
    address to
  ) external override nonReentrant returns (uint256) {
    return JoinLogic.leave(reserve, amount, id, to, reserves, collections);
  }

  function premint(uint256 id, uint256 amount, address to) external override nonReentrant {
    CollectionLogic.premint(id, amount, to, reserves, collections);
  }

  function createCollection(
    uint256 _id,
    address _reserve,
    DataTypes.CollectionConfig calldata _config
  ) external override nonReentrant {
    CollectionLogic.create(erc721implementation, _id, _reserve, _config, collections, reserves[_reserve].mToken);
  }

  function getReserveData(address underlying) external view returns (DataTypes.ReserveData memory) {
    return reserves[underlying];
  }

  function getCollectionData(uint256 id) external view returns (DataTypes.CollectionData memory) {
    return collections[id];
  }
}
