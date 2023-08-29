// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface ICampaignNFT {
    function mint(
        uint256 _amount, 
        uint8 _tokenType,
        address _to,
        string calldata _callbackData
    ) external;

    function  whitelistMint(
        uint256 _amount, 
        uint8 _tokenType,
        address _to
    ) external;

    function withdraw() external;
    
    function burn(
        uint256[] memory ids
    ) external;

    /** Function returns last tokenId at the moment */
    function lastId() external view returns (uint256);

    /**
     *      @dev Function allow ADMIN to set free transfer flag
     */
    function switchFreeTransferMode() external;

    /**
     *      @dev Set whitelis
     */
    function setWhiteList(address _to) external;
}