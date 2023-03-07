// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IFeeManager} from "../interfaces/IFeeManager.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {Events} from "../libraries/Events.sol";

/**
 * @title FeeManager contract
 * @author MoonPier
 * @notice FeeManager is a contract that stores the fee for each collection
 */
contract FeeManager is Ownable, IFeeManager {
  mapping(address => uint256) internal _feeOverride;
  uint256 internal immutable _defaultFee;

  constructor(uint256 defaultFee, address feeManagerAdmin) {
    _defaultFee = defaultFee;
    _transferOwnership(feeManagerAdmin);
  }

  function setFeeOverride(address collection, uint256 amount) external override onlyOwner {
    require(amount > 0 && amount < 2001, "FeeManager: Fee can only be set in 0 - 20%");
    _feeOverride[collection] = amount;
    emit Events.FeeOverrideSet(collection, amount);
  }

  function getFees(address collection) external view override returns (address payable, uint256) {
    if (_feeOverride[collection] > 0) {
      return (payable(owner()), _feeOverride[collection]);
    }
    return (payable(owner()), _defaultFee);
  }
}
