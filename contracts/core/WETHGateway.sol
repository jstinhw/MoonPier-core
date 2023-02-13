// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

import {IMoonFish} from "../interfaces/IMoonFish.sol";
import {IMToken} from "../interfaces/IMToken.sol";
import {IWETH} from "../interfaces/IWETH.sol";
import {IWETHGateway} from "../interfaces/IWETHGateway.sol";
import {ERC1155Receiver} from "openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import {IERC165} from "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import {ERC1155Holder} from "openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "forge-std/console2.sol";

contract WETHGateway is IWETHGateway, ReentrancyGuard, ERC1155Holder {
  IWETH internal WETH;
  IMoonFish internal MoonFish;

  constructor(address _underlying, address _moonFish) {
    WETH = IWETH(_underlying);
    MoonFish = IMoonFish(_moonFish);
    IMToken mToken = IMToken(MoonFish.getReserveData(address(WETH)).mToken);
    mToken.setApprovalForAll(address(MoonFish), true);
  }

  function joinETH(uint256 id) external payable override nonReentrant {
    WETH.deposit{value: msg.value}();
    WETH.transferFrom(address(this), address(MoonFish), msg.value);
    MoonFish.join(address(WETH), msg.value, id, msg.sender);
  }

  function leaveETH(uint256 id, uint256 amount, address to) external override nonReentrant {
    IMToken mToken = IMToken(MoonFish.getReserveData(address(WETH)).mToken);
    mToken.safeTransferFrom(msg.sender, address(this), id, amount, "");
    uint256 balance = MoonFish.leave(address(WETH), amount, id, address(this));
    WETH.withdraw(balance);

    (bool success, ) = to.call{value: balance}("");
    if (!success) {
      revert("Transfer failed.");
    }
  }

  function premint(uint256 id, uint256 amount) external override nonReentrant {}

  function supportsInterface(bytes4 interfaceId) public view override(ERC1155Receiver) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  receive() external payable {
    require(msg.sender == address(WETH), "Receive not allowed");
  }

  fallback() external payable {
    revert("Fallback not allowed");
  }
}
