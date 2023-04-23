// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC1155Burnable} from "openzeppelin-contracts/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import {ERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import {IERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";

import {Base64} from "openzeppelin-contracts/contracts/utils/Base64.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC1155Holder} from "openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {ERC1155Receiver} from "openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import {IERC165} from "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

import {IMToken} from "../interfaces/IMToken.sol";
import {Errors} from "../libraries/Errors.sol";

import {TokenIdentifiers} from "./TokenIdentifiers.sol";

/**
 * @title MToken
 * @author MoonPier
 * @notice MToken is a ERC1155 presale tokens which can redeem NFTs
 */
contract MToken is ERC1155, ERC1155Burnable, ERC1155Holder, IMToken {
  using TokenIdentifiers for uint256;
  using Strings for uint256;
  using Strings for address;

  address internal immutable underlyingAsset;
  address internal immutable moonpier;
  mapping(uint256 => uint256) public totalSupply;

  constructor(address _underlyingAsset, address _moonPier) ERC1155("") {
    underlyingAsset = _underlyingAsset;
    moonpier = _moonPier;
  }

  modifier onlyMoonPier() {
    require(_msgSender() == moonpier, "MToken: not from moonpier");
    _;
  }

  function mint(address to, uint256 id, uint256 amount) external override(IMToken) onlyMoonPier {
    totalSupply[id] += amount;
    _mint(to, id, amount, "");
  }

  function burn(address from, uint256 id, uint256 amount) public override(ERC1155Burnable, IMToken) onlyMoonPier {
    totalSupply[id] -= amount;
    _burn(from, id, amount);
    IERC20(underlyingAsset).transferFrom(address(this), from, amount);
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
        (moonpier == _msgSender() && from == address(this)),
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

  function generateSVG(uint256 id) private pure returns (bytes memory) {
    return
      bytes.concat(
        abi.encodePacked(
          '<svg xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape" xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns="http://www.w3.org/2000/svg" xmlns:svg="http://www.w3.org/2000/svg" width="210mm" height="297mm" viewBox="0 0 210 297" version="1.1" id="svg352" xml:space="preserve" inkscape:version="1.2.2 (b0a8486, 2022-12-01)" sodipodi:docname="presalebase.svg">',
          '<defs><linearGradient id="myGradient" x1="0%" y1="0%" x2="100%" y2="100%"><stop offset="0%" stop-color="#9AD5b6"/><stop offset="100%" stop-color="#83BA6f"/></linearGradient></defs><path id="path352" style="" d="m 104.07404,10.653073 a 91.000112,90.999742 0 0 0 -90.999616,90.999997 91.000112,90.999742 0 0 0 90.999616,91 91.000112,90.999742 0 0 0 91.00038,-91 91.000112,90.999742 0 0 0 -0.0165,-1.41948 75.917217,75.916908 0 0 1 -11.54695,0.91686 A 75.917217,75.916908 0 0 1 107.5939,25.233716 75.917217,75.916908 0 0 1 109.03662,10.794647 91.000112,90.999742 0 0 0 104.074,10.65307 Z" fill="url(#myGradient)"/>'
        ),
        abi.encodePacked(
          '<text x="15" y="220" fill="url(#myGradient)" font-family="Euphemia UCAS" font-size="7">',
          id.tokenCreator().toHexString(),
          '</text><text x="15" y="240" fill="url(#myGradient)" font-family="Euphemia UCAS" font-size="14">Presale Pioneer</text><text x="15" y="285" fill="url(#myGradient)" font-family="Euphemia UCAS" font-size="14">id: ',
          id.tokenIndex().toString(),
          '</text><rect x="5" y="5" width="200" height="287" rx="15" fill="none" stroke="url(#myGradient)" stroke-width="4"/><text x="135" y="285" fill="url(#myGradient)" font-family="Euphemia UCAS" font-size="14">MoonPier</text></svg>'
        )
      );
  }

  function constructTokenURI(uint256 id) internal pure returns (string memory) {
    string memory pageSVG = Base64.encode(bytes(generateSVG(id)));
    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(
            bytes(
              abi.encodePacked(
                '{"creator":"',
                id.tokenCreator().toHexString(),
                '", "downpayment":"',
                id.tokenDownpayment().toString(),
                '", "id":"',
                id.tokenIndex().toString(),
                '", "image": "',
                "data:image/svg+xml;base64,",
                pageSVG,
                '"}'
              )
            )
          )
        )
      );
  }

  function uri(uint256 id) public pure override(ERC1155, IMToken) returns (string memory) {
    return constructTokenURI(id);
  }
}
