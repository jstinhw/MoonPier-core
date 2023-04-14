// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC721AUpgradeable} from "erc721a-upgradeable/ERC721AUpgradeable.sol";
import {IERC721AUpgradeable} from "erc721a-upgradeable/IERC721AUpgradeable.sol";
import {AccessControlUpgradeable} from "openzeppelin-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import {MerkleProofUpgradeable} from "openzeppelin-upgradeable/contracts/utils/cryptography/MerkleProofUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {IERC165Upgradeable} from "openzeppelin-upgradeable/contracts/interfaces/IERC165Upgradeable.sol";

import {IERC721Presale} from "../interfaces/IERC721Presale.sol";
import {IMoonFishAddressProvider} from "../interfaces/IMoonFishAddressProvider.sol";
import {IMoonFish} from "../interfaces/IMoonFish.sol";
import {IFeeManager} from "../interfaces/IFeeManager.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {Errors} from "../libraries/Errors.sol";

/**
 * @title ERC721 contract for presale
 * @author MoonPier
 * @notice ERC721Presale is a contract that allows creators to pre-sell their collections
 */
contract ERC721Presale is
  IERC721Presale,
  ERC721AUpgradeable,
  UUPSUpgradeable,
  ReentrancyGuardUpgradeable,
  AccessControlUpgradeable
{
  // IMoonFish internal moonfish;
  bytes32 public constant DEFAULT_CREATOR_ROLE = bytes32(uint256(0x01));
  address public immutable ADMIN;
  uint256 internal _presaleTotalAmount = 0;
  IMoonFishAddressProvider internal immutable moonFishAddressProvider;

  mapping(address => uint256) internal _whitelistMintedAmount;
  mapping(address => uint256) internal _presaleMintedAmount;

  // collection params
  DataTypes.CollectionConfig internal _collectionConfig;
  bytes32 internal _merkleRoot;
  string internal _presalebaseURI;

  constructor(address addressProvider) initializer {
    moonFishAddressProvider = IMoonFishAddressProvider(addressProvider);
    ADMIN = msg.sender;
  }

  modifier onlyAdmin() {
    if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
      revert Errors.AdminOnly();
    }
    _;
  }

  modifier onlyCreator() {
    if (!hasRole(DEFAULT_CREATOR_ROLE, _msgSender())) {
      revert Errors.CreatorOnly();
    }
    _;
  }

  modifier onlyMoonFish() {
    if (msg.sender != moonFishAddressProvider.getMoonFish()) {
      revert Errors.MoonFishOnly();
    }
    _;
  }

  function initialize(
    address creator,
    string memory name,
    string memory symbol,
    DataTypes.CollectionConfig calldata collectionConfig
  ) public initializerERC721A initializer {
    __ERC721A_init(name, symbol);
    __UUPSUpgradeable_init();
    __AccessControl_init();
    __ReentrancyGuard_init();
    _setupRole(DEFAULT_ADMIN_ROLE, ADMIN);
    _setupRole(DEFAULT_CREATOR_ROLE, creator);

    _collectionConfig = collectionConfig;
  }

  function setCollectionConfig(DataTypes.CollectionConfig calldata config) external override onlyCreator {
    _collectionConfig = config;
  }

  function setBaseURI(string memory presaleBaseURI) public override onlyCreator {
    _presalebaseURI = presaleBaseURI;
  }

  function setMerkleRoot(bytes32 merkleRoot) external override onlyCreator {
    _merkleRoot = merkleRoot;
  }

  function withdraw() external override onlyCreator {
    uint256 funds = address(this).balance;
    (address payable feeRecipient, uint256 moonfishFee) = IFeeManager(moonFishAddressProvider.getFeeManager()).getFees(
      address(this)
    );
    uint256 fee = (funds * moonfishFee) / 10000;
    (bool successFee, ) = feeRecipient.call{value: fee}("");
    if (!successFee) {
      revert Errors.WithdrawFeeFailed();
    }
    funds = funds - fee;
    (bool successFund, ) = payable(_collectionConfig.fundsReceiver).call{value: funds}("");
    if (!successFund) {
      revert Errors.WithdrawFundFailed();
    }
  }

  function mint(uint256 amount) external payable override nonReentrant {
    if (block.timestamp < _collectionConfig.publicStartTime || block.timestamp > _collectionConfig.publicEndTime) {
      revert Errors.InvalidPublicMintTime();
    }
    if (
      _numberMinted(_msgSender()) - _whitelistMintedAmount[_msgSender()] - _presaleMintedAmount[_msgSender()] + amount >
      _collectionConfig.maxAmountPerAddress
    ) {
      revert Errors.ExceedMaxAmountPerAddress();
    }
    if (_totalMinted() + amount > _collectionConfig.maxSupply) {
      revert Errors.ExceedMaxSupply();
    }
    if (msg.value < _collectionConfig.publicMintPrice * amount) {
      revert Errors.InsufficientEth();
    }
    _mint(_msgSender(), amount);
  }

  function whitelistMint(
    bytes32[] calldata proof,
    uint256 amount,
    uint256 maxAmount,
    uint256 pricePerToken
  ) external payable override nonReentrant {
    if (
      !MerkleProofUpgradeable.verify(proof, _merkleRoot, keccak256(abi.encode(_msgSender(), maxAmount, pricePerToken)))
    ) {
      revert Errors.InvalidWhitelistProof();
    }

    if (msg.value < pricePerToken * amount) {
      revert Errors.InsufficientEth();
    }

    if (
      block.timestamp < _collectionConfig.whitelistStartTime || block.timestamp > _collectionConfig.whitelistEndTime
    ) {
      revert Errors.InvalidWhitelistMintTime();
    }

    if (_totalMinted() + amount > _collectionConfig.maxSupply) {
      revert Errors.ExceedMaxSupply();
    }
    if (_whitelistMintedAmount[_msgSender()] + amount > maxAmount) {
      revert Errors.ExceedWhitelistAvailableAmount();
    }
    _whitelistMintedAmount[_msgSender()] = _whitelistMintedAmount[_msgSender()] + amount;
    _mint(_msgSender(), amount);
  }

  function presaleMint(address to, uint256 amount) external override onlyMoonFish {
    if (_totalMinted() + amount > _collectionConfig.maxSupply) {
      revert Errors.ExceedMaxSupply();
    }
    if (block.timestamp < _collectionConfig.presaleStartTime || block.timestamp > _collectionConfig.presaleEndTime) {
      revert Errors.InvalidPresaleMintTime();
    }
    if (_presaleMintedAmount[to] + amount > _collectionConfig.presaleAmountPerWallet) {
      revert Errors.ExceedPresaleMaxAmountPerAddress();
    }
    if (_presaleTotalAmount + amount > _collectionConfig.presaleMaxSupply) {
      revert Errors.ExceedPresaleMaxAmount();
    }
    if (_numberMinted(to) + amount > _collectionConfig.maxAmountPerAddress) {
      revert Errors.ExceedMaxAmountPerAddress();
    }

    _presaleMintedAmount[to] = _presaleMintedAmount[to] + amount;
    _presaleTotalAmount = _presaleTotalAmount + amount;
    _mint(to, amount);
  }

  function getMinted(address minter) external view returns (uint256) {
    return _numberMinted(minter);
  }

  function getPresaleTotalAmount() external view returns (uint256) {
    return _presaleTotalAmount;
  }

  function getCollectionConfig() external view override returns (DataTypes.CollectionConfig memory) {
    return _collectionConfig;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    if (!_exists(tokenId)) {
      revert Errors.TokenNotExist();
    }
    return bytes(_presalebaseURI).length != 0 ? string(abi.encodePacked(_presalebaseURI, _toString(tokenId))) : "";
  }

  function getMerkleRoot() external view override returns (bytes32) {
    return _merkleRoot;
  }

  function getWhitelistMintedAmount(address minter) external view override returns (uint256) {
    return _whitelistMintedAmount[minter];
  }

  function getPresaleMintedAmount(address minter) external view override returns (uint256) {
    return _presaleMintedAmount[minter];
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view override(ERC721AUpgradeable, AccessControlUpgradeable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function _authorizeUpgrade(address newImplementation) internal override onlyAdmin {}
}
