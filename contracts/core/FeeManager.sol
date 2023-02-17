// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IFeeManager} from "../interfaces/IFeeManager.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract FeeManager is Ownable, IFeeManager {
  mapping(address => uint256) private feeOverride;
  uint256 private immutable defaultFee;

  event FeeOverrideSet(address indexed, uint256 indexed);

  constructor(uint256 _defaultFee, address feeManagerAdmin) {
    defaultFee = _defaultFee;
    _transferOwnership(feeManagerAdmin);
  }

  function setFeeOverride(address _contract, uint256 _amount) external onlyOwner {
    require(_amount < 2001, "FeeManager: Fee too high");
    feeOverride[_contract] = _amount;
    emit FeeOverrideSet(_contract, _amount);
  }

  function getFees(address _contract) external view returns (address payable, uint256) {
    if (feeOverride[_contract] > 0) {
      return (payable(owner()), feeOverride[_contract]);
    }
    return (payable(owner()), defaultFee);
  }
}
