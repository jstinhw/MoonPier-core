// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library Errors {
  error AdminOnly();
  error PublicMintInvalidTime();
  error InsufficientSupply();
  error PublicExceedMaxAMountPerAddress();
  error WhitelistMintInvalidTime();
  error WhitelistExceedMaxAMountPerAddress();
  error WhitelistInvalidProof();
  error WhitelistInsufficientPrice();
  error TransferFeeFailed();
  error TransferFundFailed();
  error PresaleExceedMaxAMountPerAddress();
  error PresaleInvalidMint();
  error CollectionNotExist();
  error MoonFishOnly();
}
