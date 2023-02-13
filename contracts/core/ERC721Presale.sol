// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC721AUpgradeable} from "erc721a-upgradeable/ERC721AUpgradeable.sol";
import {IERC721AUpgradeable} from "erc721a-upgradeable/IERC721AUpgradeable.sol";
import {AccessControlUpgradeable} from "openzeppelin-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import {MerkleProofUpgradeable} from "openzeppelin-upgradeable/contracts/utils/cryptography/MerkleProofUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {IERC165Upgradeable} from "openzeppelin-upgradeable/contracts/interfaces/IERC2981Upgradeable.sol";

import {IMoonFishAddressProvider} from "../interfaces/IMoonFishAddressProvider.sol";
import {IMoonFish} from "../interfaces/IMoonFish.sol";
import {IFeeManager} from "../interfaces/IFeeManager.sol";
import {PublicMulticall} from "../libraries/PublicMulticall.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {Errors} from "../libraries/Errors.sol";

import "forge-std/console2.sol";

contract ERC721Presale is
  ERC721AUpgradeable,
  UUPSUpgradeable,
  ReentrancyGuardUpgradeable,
  AccessControlUpgradeable,
  PublicMulticall
{
  // IMoonFish internal moonfish;
  // IFeeManager internal immutable feeManager;
  IMoonFishAddressProvider public immutable moonFishAddressProvider;

  mapping(address => uint256) public whitelistMintedAmount;
  mapping(address => uint256) public presaleMintedAmount;

  // collection params
  DataTypes.CollectionConfig public collectionConfig;
  bytes32 public merkleRoot;
  string public baseURI;

  constructor(address _moonFishaddressProvider) initializer {
    moonFishAddressProvider = IMoonFishAddressProvider(_moonFishaddressProvider);
  }

  modifier onlyAdmin() {
    if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
      revert Errors.AdminOnly();
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
    address _admin,
    string memory _name,
    string memory _symbol,
    DataTypes.CollectionConfig calldata _collectionConfig
  ) public initializerERC721A initializer {
    __ERC721A_init(_name, _symbol);
    __UUPSUpgradeable_init();
    __AccessControl_init();
    __ReentrancyGuard_init();
    _setupRole(DEFAULT_ADMIN_ROLE, _admin);

    collectionConfig = _collectionConfig;

    // if (_setConfigdata.length > 0) {
    //   // Setup temporary role
    //   _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    //   // Execute setupCalls
    //   multicall(_setConfigdata);
    //   // Remove temporary role
    //   _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    // }
  }

  function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

  function setCollectionConfig(
    uint256 _maxAmountPerAddress,
    uint256 _publicMintPrice,
    uint256 _publicStartTime,
    uint256 _publicEndTime,
    uint256 _whitelistMintPrice,
    uint256 _whitelistStartTime,
    uint256 _whitelistEndTime,
    uint256 _presaleMintPrice,
    uint256 _presaleAmountPerWallet
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    collectionConfig.maxAmountPerAddress = _maxAmountPerAddress;
    collectionConfig.publicMintPrice = _publicMintPrice;
    collectionConfig.publicStartTime = _publicStartTime;
    collectionConfig.publicEndTime = _publicEndTime;
    collectionConfig.whitelistMintPrice = _whitelistMintPrice;
    collectionConfig.whitelistStartTime = _whitelistStartTime;
    collectionConfig.whitelistEndTime = _whitelistEndTime;
    collectionConfig.presaleMintPrice = _presaleMintPrice;
    collectionConfig.presaleAmountPerWallet = _presaleAmountPerWallet;
  }

  function setMerkleRoot(bytes32 _merkleRoot) external onlyRole(DEFAULT_ADMIN_ROLE) {
    merkleRoot = _merkleRoot;
  }

  function mint(uint256 amount) external {
    if (block.timestamp < collectionConfig.publicStartTime || block.timestamp > collectionConfig.publicEndTime) {
      revert Errors.PublicMintInvalidTime();
    }

    if (_totalMinted() + amount > collectionConfig.maxSupply) {
      revert Errors.InsufficientSupply();
    }
    if (
      _numberMinted(_msgSender()) - whitelistMintedAmount[_msgSender()] - presaleMintedAmount[_msgSender()] + amount >
      collectionConfig.maxAmountPerAddress
    ) {
      revert Errors.PublicExceedMaxAMountPerAddress();
    }
    _mint(_msgSender(), amount);
  }

  function whitelistMint(
    bytes32[] calldata _proof,
    uint256 _amount,
    uint256 _maxAmount,
    uint256 _pricePerToken
  ) external payable {
    if (
      !MerkleProofUpgradeable.verify(
        _proof,
        merkleRoot,
        keccak256(abi.encode(_msgSender(), _maxAmount, _pricePerToken))
      )
    ) {
      revert Errors.WhitelistInvalidProof();
    }

    if (msg.value <= _pricePerToken * _amount) {
      revert Errors.WhitelistInsufficientPrice();
    }

    if (block.timestamp < collectionConfig.whitelistStartTime || block.timestamp > collectionConfig.whitelistEndTime) {
      revert Errors.WhitelistMintInvalidTime();
    }

    if (_totalMinted() + _amount > collectionConfig.maxSupply) {
      revert Errors.InsufficientSupply();
    }
    if (whitelistMintedAmount[_msgSender()] + _amount > _maxAmount) {
      revert Errors.WhitelistExceedMaxAMountPerAddress();
    }
    _mint(_msgSender(), _amount);
    whitelistMintedAmount[_msgSender()] = whitelistMintedAmount[_msgSender()] + _amount;
  }

  function presaleMint(address to, uint256 amount) external onlyMoonFish {
    if (_totalMinted() + collectionConfig.presaleAmountPerWallet > collectionConfig.maxSupply) {
      revert Errors.InsufficientSupply();
    }
    if (presaleMintedAmount[to] + collectionConfig.presaleAmountPerWallet > collectionConfig.presaleAmountPerWallet) {
      revert Errors.PresaleExceedMaxAMountPerAddress();
    }

    _mint(to, amount);
    presaleMintedAmount[to] = presaleMintedAmount[to] + amount;
  }

  function withdraw() external onlyAdmin {
    uint256 funds = address(this).balance;
    (address payable feeRecipient, uint256 moonfishFee) = IFeeManager(moonFishAddressProvider.getFeeManager()).getFees(
      address(this)
    );
    uint256 fee = (funds * moonfishFee) / 10000;
    (bool successFee, ) = feeRecipient.call{value: fee}("");
    if (!successFee) {
      revert Errors.TransferFeeFailed();
    }
    funds = funds - fee;
    (bool successFund, ) = payable(collectionConfig.fundsReceiver).call{value: funds}("");
    if (!successFund) {
      revert Errors.TransferFundFailed();
    }
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    if (!_exists(tokenId)) {
      revert IERC721AUpgradeable.URIQueryForNonexistentToken();
    }
    return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : "";
  }

  function setBaseURI(string memory _baseURI) public onlyAdmin {
    baseURI = _baseURI;
  }

  function supportsInterface(
    bytes4 interfaceId
  )
    public
    view
    override(
      // IERC165Upgradeable,
      ERC721AUpgradeable,
      AccessControlUpgradeable
    )
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function getPresalePrice() external view returns (uint256) {
    return collectionConfig.presaleMintPrice;
  }
}
