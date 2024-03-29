// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

import {IMoonPier} from "../interfaces/IMoonPier.sol";
import {IMToken} from "../interfaces/IMToken.sol";
import {IWETH} from "../interfaces/IWETH.sol";
import {IWETHGateway} from "../interfaces/IWETHGateway.sol";
import {ERC1155Receiver} from "openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import {IERC165} from "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import {ERC1155Holder} from "openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {IERC721Presale} from "../interfaces/IERC721Presale.sol";
import {Errors} from "../libraries/Errors.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {TokenIdentifiers} from "./TokenIdentifiers.sol";

/**
 * @title WETHGateway contract
 * @author MoonPier
 * @notice WETHGateway is a contract that allows users to join and leave moonpier collections using ETH
 */
contract WETHGateway is IWETHGateway, ReentrancyGuard, ERC1155Holder {
  using TokenIdentifiers for uint256;

  IWETH internal immutable WETH;
  IMoonPier internal immutable _moonPier;

  constructor(address underlying, address moonPier) {
    WETH = IWETH(underlying);
    _moonPier = IMoonPier(moonPier);
    IMToken mToken = IMToken(_moonPier.getReserveData(address(WETH)).mToken);
    mToken.setApprovalForAll(address(_moonPier), true);
  }

  function joinETH(uint256 id) external payable override nonReentrant {
    WETH.deposit{value: msg.value}();
    WETH.transferFrom(address(this), address(_moonPier), msg.value);
    _moonPier.join(address(WETH), id, msg.value, msg.sender);
  }

  function leaveETH(uint256 id, uint256 amount, address to) external override nonReentrant {
    IMToken mToken = IMToken(_moonPier.getReserveData(address(WETH)).mToken);
    uint256 balance = mToken.balanceOf(msg.sender, id);

    if (balance < amount) {
      revert Errors.GatewayLeaveInsufficientBalance();
    }
    mToken.safeTransferFrom(msg.sender, address(this), id, amount, "");
    uint256 withdrawAmount = _moonPier.leave(address(WETH), id, amount, address(this));
    WETH.withdraw(withdrawAmount);

    (bool success, ) = to.call{value: withdrawAmount}("");
    if (!success) {
      revert("Transfer failed.");
    }
  }

  function premint(uint256 id, uint256 amount) external override nonReentrant {
    DataTypes.CollectionData memory collectionData = _moonPier.getCollectionData(id);
    if (collectionData.collection == address(0)) {
      revert Errors.CollectionNotExist();
    }
    uint256 downpayment = id.tokenDownpayment();
    uint256 price = (amount * collectionData.presalePrice * (10000 - downpayment)) / 10000;

    IMToken mToken = IMToken(_moonPier.getReserveData(address(WETH)).mToken);
    uint balance = mToken.balanceOf(msg.sender, id);
    if (balance < price) {
      revert Errors.GatewayPremintInsufficientBalance();
    }
    mToken.safeTransferFrom(msg.sender, address(this), id, price, "");
    _moonPier.premint(id, amount, msg.sender);
  }

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
