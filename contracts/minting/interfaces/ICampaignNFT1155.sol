// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface ICampaignNFT1155 {
    function mint(
        uint256 _amount, 
        uint8 _tokenType,
        address _to
    ) external;

    function  whitelistMint(
        uint256 _amount, 
        uint8 _tokenType,
        address _to
    ) external;

    function withdraw() external;
    
    function burnNFT(
        uint256[] memory ids
    ) external;

    function initialize(
        address _marketOwnerAddress,
        string memory _baseMetadataUri,
        address _campaignPaymentAddress,
        bool _isFixedTokenId, 
        IERC20 _coinToken,
        string memory _symbol,
        string memory _name,
        address _adminAddress
    ) external;
}