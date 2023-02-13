// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {DataTypes} from "../libraries/DataTypes.sol";
import {IMToken} from "../interfaces/IMToken.sol";

/**
 * @title JoinLogic library
 * @author MoonPier
 * @notice JoinLogic library contains the logic for joining a collection
 */
library JoinLogic {
  event Join(address indexed reserve, address indexed user, uint256 amount, uint256 indexed id);

  event Leave(address indexed reserve, address indexed user, uint256 amount, uint256 indexed id);

  function join(
    address reserve,
    uint256 amount,
    uint256 id,
    address to,
    mapping(address => DataTypes.ReserveData) storage reserves,
    mapping(uint256 => DataTypes.CollectionData) storage collections
  ) external {
    address mToken = reserves[reserve].mToken;
    require(collections[id].collection == address(0));
    require(mToken != address(0), "MoonFish: invalid reserve");

    IERC20(reserve).transferFrom(address(this), mToken, amount);

    uint256 premintedAmount = (amount * (100 - reserves[reserve].downpaymentRate)) / 100;
    uint256 downpayment = amount - premintedAmount;

    IMToken(mToken).mint(mToken, id, downpayment);
    IMToken(mToken).mint(to, id, premintedAmount);

    emit Join(reserve, to, amount, id);
  }

  function leave(
    address reserve,
    uint256 amount,
    uint256 id,
    address to,
    mapping(address => DataTypes.ReserveData) storage reserves,
    mapping(uint256 => DataTypes.CollectionData) storage collections
  ) external returns (uint256) {
    address mToken = reserves[reserve].mToken;
    require(mToken != address(0), "MoonFish: invalid reserve");

    uint256 withdrawAmount = amount; // (amount * 100) / (100 - reserves[reserve].downpaymentRate);
    uint256 downpayment;
    if (collections[id].collection == address(0)) {
      withdrawAmount = (amount * 100) / (100 - reserves[reserve].downpaymentRate);
      downpayment = withdrawAmount - amount;
      IMToken(mToken).safeTransferFrom(mToken, to, id, downpayment, "");
    }

    IMToken(mToken).burn(to, id, withdrawAmount);

    emit Leave(reserve, to, amount, id);
    return withdrawAmount;
  }
}
