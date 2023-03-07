// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library Errors {
  // moonPier Errors
  error CollectionNotExist();
  error LeaveInsufficientBalance();
  error WithdrawInsufficientBalance();
  error PremintInsufficientBalance();
  error GatewayLeaveInsufficientBalance();
  error GatewayPremintInsufficientBalance();
  error GatewayWithdrawInsufficientBalance();

  // erc721presale Errors
  error AdminOnly();
  error MoonFishOnly();
  error WithdrawFundFailed();
  error WithdrawFeeFailed();
  error InsufficientEth();
  error InvalidPublicMintTime();
  error ExceedMaxAmountPerAddress();
  error ExceedMaxSupply();
  error InvalidWhitelistProof();
  error InvalidWhitelistMintTime();
  error ExceedWhitelistAvailableAmount();
  error InvalidPresaleMintTime();
  error ExceedPresaleMaxAmount();
  error ExceedPresaleMaxAmountPerAddress();
}
