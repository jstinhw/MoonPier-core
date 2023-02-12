// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import {Test} from "forge-std/Test.sol";

contract Utils is Test {
  function createUsers(uint256 userNum)
      external
      returns (address[] memory)
  {
      address[] memory users = new address[](userNum);

      for (uint256 i = 0; i < userNum; i++) {
          // This will create a new address using `keccak256(i)` as the private key
          address user = vm.addr(uint256(keccak256(abi.encodePacked(i))));
          vm.deal(user, 1000 ether);
          users[i] = user;
      }

      return users;
  }
}