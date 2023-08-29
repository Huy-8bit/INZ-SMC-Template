// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IImplementation {
    function isOwnerOf(
        address checkingAddress,
        address nftAddress,
        uint256 tokenId,
        uint256 amount
    ) external view returns (bool);

    function isApproved(
        address owner,
        address spender,
        address nftAddress,
        uint256 tokenId
    ) external view returns (bool);

    function performTransfer(
        address token,
        address from,
        address to,
        uint256 identifier,
        uint256 amount
    ) external;
}