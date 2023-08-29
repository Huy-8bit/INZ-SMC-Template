// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ICampaignNFT.sol";

interface IDappCreator {
    /**
     *      @dev Defines using Structs
     */
    struct Proof {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
    }

    function mintingFromGateway(
        ICampaignNFT _nftCollection,
        uint8 _nftType,
        uint256 _amount,
        uint256 _platformFee,
        uint256 _discount,
        bool _isWhitelistMint,
        Proof memory _proof,
        string memory _callbackData,
        address _to
    ) external payable;
}
