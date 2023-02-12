// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC1155Burnable} from "openzeppelin-contracts/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import {ERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import {IERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC1155Holder} from "openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {ERC1155Receiver} from "openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import {IERC165} from "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import {IMToken} from "../interfaces/IMToken.sol";
import "forge-std/console2.sol";

contract MToken is ERC1155, ERC1155Burnable, ERC1155Holder, IMToken {
  address public immutable underlyingAsset;
  address internal immutable moonfish;

  constructor(address _underlyingAsset, address _moonFish) ERC1155("") {
    underlyingAsset = _underlyingAsset;
    moonfish = _moonFish;
  }

  modifier onlyMoonFish() {
    require(_msgSender() == moonfish);
    _;
  }

  function mint(address to, uint256 id, uint256 amount) external override(IMToken) onlyMoonFish {
    _mint(to, id, amount, "");
    emit Mint(to, id, amount);
  }

  function burn(address from, uint256 id, uint256 amount) public override(ERC1155Burnable, IMToken) onlyMoonFish {
    _burn(from, id, amount);
    IERC20(underlyingAsset).transferFrom(address(this), from, amount);

    emit Burn(from, id, amount);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public virtual override(ERC1155, IERC1155) {
    require(
      from == _msgSender() ||
        isApprovedForAll(from, _msgSender()) ||
        (moonfish == _msgSender() && from == address(this)),
      "ERC1155: caller is not token owner or approved"
    );
    _safeTransferFrom(from, to, id, amount, data);
  }

  function getUnderlyingAsset() external view override returns (address) {
    return underlyingAsset;
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC1155, ERC1155Receiver, IERC165) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}
