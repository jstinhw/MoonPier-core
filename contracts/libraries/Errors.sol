// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library Errors {
  error AdminOnly();
  error PublicMintInvalidTime();
  error InsufficientSupply();
  error PublicExceedMaxAMountPerAddress();
  error WhitelistMintInvalidTime();
  error WhitelistExceedAvailableAmount();
  error WhitelistInvalidProof();
  error WhitelistInsufficientPrice();
  error TransferFeeFailed();
  error TransferFundFailed();
  error PresaleExceedMaxAMountPerAddress();
  error PresaleInvalidMint();
  error CollectionNotExist();
  error MoonFishOnly();
  error GatewayLeaveInsufficientBalance();
  error MoonFishLeaveInsufficientBalance();
  error GatewayPremintInsufficientBalance();
  error MoonFishPremintInsufficientBalance();
  error MoonFishCollectionNotExist();
  error MoonFishWithdrawInsufficientBalance();
  error GatewayWithdrawInsufficientBalance();
  error InsufficientEth();
}
