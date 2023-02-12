// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IFeeManager {
  function getFees(address sender) external returns (address payable, uint256);
}
