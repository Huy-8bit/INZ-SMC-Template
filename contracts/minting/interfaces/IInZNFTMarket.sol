// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IInZNFTMarket {
    function getMarketFeePercent(address) external view returns (uint16);
}