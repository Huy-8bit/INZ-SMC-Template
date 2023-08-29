// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ICampaignNFT.sol";
import "./IDappCreator.sol";

interface IGatewayNFT {
    function mintToDappCreator(
        address _dappCreator,
        ICampaignNFT _nftCollection,
        uint8 _nftType,
        uint256 _amount,
        uint256 _platformFee,
        uint256 _discount,
        bool _isWhitelistMint,
        IDappCreator.Proof memory _proof,
        string memory _callbackData,
        address _to
    ) external payable;

    function withdrawETH(
        address _treasury,
        address _to,
        uint256 _amount,
        address _collectionAddress
    ) external payable;
}
