// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "../TokenTransferrer.sol";
import "../../interfaces/IImplementation.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract ERC721Implementation is TokenTransferrer, IImplementation {
    
    function isOwnerOf(
        address checkingAddress,
        address nftAddress,
        uint256 tokenId,
        uint256 amount
    ) external override view returns (bool) {
        require(amount == 1, "Invalid amount of ERC721 token");
        address owner = IERC721(nftAddress).ownerOf(tokenId);
        return (owner == checkingAddress);
    }

    function isApproved(
        address owner,
        address spender,
        address nftAddress,
        uint256 tokenId
    ) external override view returns (bool) {
        require(owner != address(0), "ERC721: Invalid owner of token");
        return (spender == IERC721(nftAddress).getApproved(tokenId));
    }

    function performTransfer(
        address token,
        address from,
        address to,
        uint256 identifier,
        uint256 amount
    ) external {
        require(amount == 1, "Invalid amount of ERC721 token");
        _performERC721Transfer(token, from, to, identifier);
    }
}