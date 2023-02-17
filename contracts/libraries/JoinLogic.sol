// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

import {DataTypes} from "../libraries/DataTypes.sol";
import {IMToken} from "../interfaces/IMToken.sol";
import {Errors} from "../libraries/Errors.sol";
import "forge-std/console2.sol";
import {TokenIdentifiers} from "../core/TokenIdentifiers.sol";

/**
 * @title JoinLogic library
 * @author MoonPier
 * @notice JoinLogic library contains the logic for joining a collection
 */

library JoinLogic {
  using TokenIdentifiers for uint256;
  event Join(address indexed reserve, address indexed user, uint256 amount, uint256 indexed id);

  event Leave(address indexed reserve, address indexed user, uint256 amount, uint256 indexed id);

  event Withdraw(address indexed user, uint256 indexed id, uint256 indexed amount);

  modifier onlyCreator(uint256 id, address creator) {
    require(_isCreator(id, creator), "Create: not creator");
    _;
  }

  function join(
    address reserve,
    uint256 id,
    uint256 amount,
    address to,
    mapping(address => DataTypes.ReserveData) storage reserves,
    mapping(uint256 => DataTypes.CollectionData) storage collections
  ) external {
    address mToken = reserves[reserve].mToken;
    require(collections[id].collection == address(0), "Join: collection exists");
    require(mToken != address(0), "Join: invalid reserve");

    IERC20(reserve).transferFrom(address(this), mToken, amount);

    uint256 premintedAmount = (amount * (100 - reserves[reserve].downpaymentRate)) / 100;
    uint256 downpayment = amount - premintedAmount;

    IMToken(mToken).mint(mToken, id, downpayment);
    IMToken(mToken).mint(to, id, premintedAmount);

    emit Join(reserve, to, amount, id);
  }

  function leave(
    address reserve,
    uint256 id,
    uint256 amount,
    address to,
    mapping(address => DataTypes.ReserveData) storage reserves,
    mapping(uint256 => DataTypes.CollectionData) storage collections
  ) external returns (uint256) {
    address mToken = reserves[reserve].mToken;
    require(mToken != address(0), "Leave: invalid reserve");
    require(amount != 0, "Leave: amount cannot be zero");

    uint256 downpayment = (amount * reserves[reserve].downpaymentRate) / (100 - reserves[reserve].downpaymentRate);
    uint256 withdrawAmount = amount;

    uint256 balance = IMToken(mToken).balanceOf(to, id);

    if (balance < withdrawAmount) {
      revert Errors.MoonFishLeaveInsufficientBalance();
    }

    if (collections[id].collection == address(0)) {
      withdrawAmount = amount + downpayment;
      IMToken(mToken).safeTransferFrom(mToken, to, id, downpayment, "");
    }

    IMToken(mToken).burn(to, id, withdrawAmount);

    emit Leave(reserve, to, amount, id);
    return withdrawAmount;
  }

  function withdraw(
    uint256 id,
    uint256 amount,
    address gateway,
    address to,
    mapping(address => DataTypes.ReserveData) storage reserves,
    mapping(uint256 => DataTypes.CollectionData) storage collections
  ) external onlyCreator(id, to) returns (uint256) {
    DataTypes.CollectionData memory cData = collections[id];

    if (cData.collection == address(0)) {
      revert Errors.MoonFishCollectionNotExist();
    }
    address reserve = cData.reserve;
    address mToken = reserves[reserve].mToken;
    require(mToken != address(0), "Withdraw: invalid reserve");
    require(amount != 0, "Withdraw: amount cannot be zero");

    uint256 balance = IMToken(mToken).balanceOf(gateway, id);
    if (balance < amount) {
      revert Errors.MoonFishWithdrawInsufficientBalance();
    }
    IMToken(mToken).burn(gateway, id, amount);

    emit Withdraw(to, id, amount);
    return amount;
  }

  function _isCreator(uint256 _id, address _address) internal pure returns (bool) {
    return _address == _id.tokenCreator();
  }
}
