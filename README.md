# MoonPier

MoonPier is a protocol for conducting NFT presales where sellers can sell NFTs using ETH instead of collecting allowlist.

## Table of Contents
- [MoonPier](#moonpier)
- [Why MoonPier](#why-moonpier)
- [MoonPier Contracts](#moonpier-contracts)
- [Install](#install)
- [Usage](#usage)

## Why MoonPier
MoonPier is a protocol for conducting NFT presales where sellers can sell NFTs using ETH instead of collecting allowlist. When buyers participate in the presale, they premint the collection and receive mTokens which can be redeemed later for the NFT created by the collection creators. 

This system allows for a streamlined and simplified presale process, and make creators sell to early supporter directly rather than only collecting allowlist before launch.


## MoonPier protocol contracts
[MoonPier.sol](https://github.com/jstinhw/MoonPier-core/blob/readme/contracts/core/MoonPier.sol) - Entrypoint to handle presale

[MToken.sol](https://github.com/jstinhw/MoonPier-core/blob/readme/contracts/core/MToken.sol) - ERC1155 tokens contract which can be used to redeem NFT once creator accept the presale funds

[ERC721Presale.sol](https://github.com/jstinhw/MoonPier-core/blob/readme/contracts/core/ERC721Presale.sol) - Modified ERC721 to support presale protocol



## Install
Install dependencies and compile contracts
```
git clone 
yarn install
yarn build
```

## Usage

### Lint contracts
```
yarn lint
```

### Run forge tests
run test with forge
```
yarn test:forge
```

