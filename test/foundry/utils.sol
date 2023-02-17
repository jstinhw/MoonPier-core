// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import {Test} from "forge-std/Test.sol";

contract Utils is Test {
  struct Proof {
    bytes32 root;
    bytes32[] proof;
    uint256 amount;
    uint256 price;
  }

  function createUsers(uint256 userNum) external returns (address[] memory) {
    address[] memory users = new address[](userNum);

    for (uint256 i = 0; i < userNum; i++) {
      // This will create a new address using `keccak256(i)` as the private key
      address user = vm.addr(uint256(keccak256(abi.encodePacked(i))));
      vm.deal(user, 1000 ether);
      users[i] = user;
    }

    return users;
  }

  function getMerkleTree(uint256 id) external pure returns (Proof memory) {
    bytes32 root = 0x003ab06c16a03cad00c54de2e911cc57f95338701bf6690f43dce0507b18c070;
    if (id == 0) {
      // alcie can mint 1 token with 1 ether per token
      bytes32[] memory proof = new bytes32[](2);
      proof[0] = 0xc0fea8765bcf149467a47631ba8606579ce9e060196d7bdb72f9842422f8979e;
      proof[1] = 0x9b61c78e338e02e4939a6569ecc3ab21bae0d6c0447299e44016d13f777e96dd;
      return Proof({root: root, proof: proof, amount: 1, price: 1 ether});
    } else if (id == 1) {
      // bob can mint 2 token with 2 ether per token
      bytes32[] memory proof = new bytes32[](2);
      proof[0] = 0xd28fd3c48bc62cff8b6870a9f5fa5d7637b4e082890ea6d4f038553959392229;
      proof[1] = 0x9b61c78e338e02e4939a6569ecc3ab21bae0d6c0447299e44016d13f777e96dd;
      return Proof({root: root, proof: proof, amount: 2, price: 3 ether});
    } else {
      // alcie can mint 3 token with 3 ether per token
      bytes32[] memory proof = new bytes32[](1);
      proof[0] = 0xa86bcc6536e1d6db744a09b3a3de7bdc80e9c5b9c675d8003c5e3f5f2b0d7969;
      return Proof({root: root, proof: proof, amount: 3, price: 3 ether});
    }
  }
}
