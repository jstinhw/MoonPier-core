// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "forge-std/console2.sol";

/*
  DESIGN NOTES:
  Token ids are a concatenation of:
 * creator: hex address of the creator of the token. 160 bits
 * index: Index for this token (the regular ID), up to 2^82 - 1. 82 bits
 * downpayment: downpayment token, 0 - 1 (unit 0.01 %).  14 bits*/
/**
 * @title TokenIdentifiers
 * support for authentication and metadata for token ids
 */
library TokenIdentifiers {
  uint8 internal constant ADDRESS_BITS = 160;
  uint8 internal constant INDEX_BITS = 82;
  uint8 internal constant DOWNPAYMENT_BITS = 14;

  uint256 internal constant DOWNPAYMENT_MASK = (uint256(1) << DOWNPAYMENT_BITS) - 1;
  uint256 internal constant INDEX_MASK = ((uint256(1) << INDEX_BITS) - 1) ^ DOWNPAYMENT_MASK;

  function tokenDownpayment(uint256 _id) internal pure returns (uint256) {
    return (_id & DOWNPAYMENT_MASK) > 10000 ? 10000 : (_id & DOWNPAYMENT_MASK);
  }

  function tokenIndex(uint256 _id) internal pure returns (uint256) {
    return _id & INDEX_MASK;
  }

  function tokenCreator(uint256 _id) internal pure returns (address) {
    return address(uint160(_id >> (INDEX_BITS + DOWNPAYMENT_BITS)));
  }
}
