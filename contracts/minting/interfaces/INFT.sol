// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface INFT {
    function uri(uint256 _tokenId) external view returns (string memory);
}

