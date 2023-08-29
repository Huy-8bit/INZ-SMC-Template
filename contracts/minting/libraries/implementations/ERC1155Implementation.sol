// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "../TokenTransferrer.sol";
import "../../interfaces/IImplementation.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";


contract ERC1155Implementation is TokenTransferrer, IImplementation {
    function isOwnerOf(
        address checkingAddress,
        address nftAddress,
        uint256 tokenId,
        uint256 amount
    ) external override view returns (bool) {
        uint256 balance = IERC1155(nftAddress).balanceOf(checkingAddress, tokenId);
        return (balance == amount);
    }

    function isApproved(
        address owner,
        address spender,
        address nftAddress,
        uint256 tokenId
    ) external override view returns (bool) {
        require(tokenId > 0, "ERC1155: Invalid tokenId");
        return IERC1155(nftAddress).isApprovedForAll(owner, spender);
    }

    function performTransfer(
        address token,
        address from,
        address to,
        uint256 identifier,
        uint256 amount
    ) external {
        _performERC1155Transfer(token, from, to, identifier, amount);
    }
}
