// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC1967Proxy} from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract ERC721PresaleProxy is ERC1967Proxy {
  constructor(address _implementation, bytes memory _data) payable ERC1967Proxy(_implementation, _data) {}
}
