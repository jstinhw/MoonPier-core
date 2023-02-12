// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

import {IMoonFish} from "../interfaces/IMoonFish.sol";
import {IMToken} from "../interfaces/IMToken.sol";
import {IWETH} from "../interfaces/IWETH.sol";
import {IWETHGateway} from "../interfaces/IWETHGateway.sol";
import "forge-std/console2.sol";

contract WETHGateway is IWETHGateway, ReentrancyGuard {
  IWETH internal WETH;
  IMoonFish internal MoonFish;

  constructor(address _underlying, address _moonFish) {
    WETH = IWETH(_underlying);
    MoonFish = IMoonFish(_moonFish);
  }

  function joinETH(uint256 id) external payable override nonReentrant {
    WETH.deposit{value: msg.value}();
    WETH.transferFrom(address(this), address(MoonFish), msg.value);
    MoonFish.join(address(WETH), msg.value, id, msg.sender);
  }

  function leaveETH(uint256 id, uint256 amount, address to) external override nonReentrant {
    MoonFish.leave(address(WETH), amount, id, to);
  }

  function premint(uint256 id, uint256 amount) external override nonReentrant {}
}
