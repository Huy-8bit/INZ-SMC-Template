// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "../libraries/InZNFTTypeDetail.sol";

interface IConfiguration {
    /**
     *  @notice Function allows Factory to add new deployed collection
     */
    function InsertNewCollectionAddress(address _nftCollection) external;

    /**
     *  @notice Function config for each Collection
     */
    function configCollection(
        address _collectionAddress,
        uint8 _nftType,
        uint256 _price,
        uint256 _totalSupply,
        string memory _baseMetadataUri,
        address _creatorAddress,
        address _payToken
    ) external;

    /**
     *  @notice Function config tokenURI() of each Collection
     */
    function configCollectionURI(
        address _collectionAddress,
        string memory _baseMetadataUri
    ) external;

    /**
     *  @notice Function update new Creator Collection
     */
    function updateCreatorCollection( 
        address _newCreator,
        address _collectionAddress
    ) external;

    /**
     *  @notice Function update new payToken Collection
     */
    function updatePayTokenCollection(
        address _collectionAddress,
        address _payToken
    ) external;

    /**
     *  @notice Function update new contracts: Factory, DappCreator, InZTreasury
     */
    function updateConfigContract(
        address _nftFactory,
        address _dappCreator,
        address _treasury
    ) external;

    /**
     *  @notice Function allows Dapp Creator call to get price
     */
    function getCreatorFromTreasury(
        address _collectionAddress
    ) external view  returns(address);

    /**
     *  @notice Function get tokenURI() of Collection
     */
    function getCollectionURI(
        address _nftCollection,
        uint256 _tokenID
    ) external view returns (string memory);

    /**
     *  @notice Function allows Dapp Creator call to get price
     */
    function getCollectionPrice(
        address _nftCollection,
        uint8 _nftType
    ) external view returns (uint256, address);

    /**
     *  @notice Function get address Creator Collection From DappCreator
     */
    function getCreatorCollection(
        address _collectionAddress
    ) external view returns(address);

    /**
     *  @notice Function get oldPayToken Collection
     */
    function getPayTokenCollection(
        address _collectionAddress
    ) external view returns(address);

    /**
     *  @notice Function get info NftDetail by nftType
     */
    function getNftTypeDetail(
        address _collectionAddress, 
        uint8 _tokenType
    ) external view returns (InZNFTTypeDetail.NFTTypeDetail memory);

    /**
     *  @notice Function check the rarity is valid or not in the current state of system
     *  @dev Function used for all contract call to for validations
     *  @param _nftCollection The address of the collection contract need to check
     *  @param _nftType The type need to check
     */
    function checkValidMintingAttributes(
        address _nftCollection,
        uint8 _nftType
    ) external view returns (bool);

    /**
     *  @notice function allows external to get DaapNFTCreator
     */
    function getNftCreator() external view returns (address);
}
