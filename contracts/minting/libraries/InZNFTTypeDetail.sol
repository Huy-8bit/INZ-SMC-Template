// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

library InZNFTTypeDetail {
    struct NFTTypeDetail {    
        uint8 nftType;       // Type of nft  
        uint256 totalSupply; // total supply of this nft type
        uint256 price;       // price of this nft type
    }
}