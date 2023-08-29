// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./libraries/InZNFTTypeDetail.sol";

contract Configurations is AccessControlUpgradeable {
    // Add the library methods
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // NFT Factory Address
    address public NFT_FACTORY;

    // Config URI NFT
    // NFT address => uri
    mapping(address => string) public uriNFTs;

    // NFT Collection => Creator Collection
    mapping(address => address) public creatorCollection;

    // NFT Collection  => ERC20 Token
    mapping(address => address) public payTokenCollection;

    // Dapp Creator
    address public DAPP_CREATOR;

    // Dapp Creator
    address public INZ_TREASURY;

    // List of NFT collections
    EnumerableSet.AddressSet private nftCollectionsList;

    // Detail Config of each Collection
    mapping(address => mapping(uint8 => InZNFTTypeDetail.NFTTypeDetail))
        public nftTypeDetails;

    // modifier to check from Factory or not
    modifier onlyFromFactory() {
        require(
            msg.sender == NFT_FACTORY,
            "Can only call from Factory contract"
        );
        _;
    }

    // Modifier just accept call from dappCreator
    modifier onlyFromDappCreator() {
        require(
            msg.sender == DAPP_CREATOR,
            "Can only call from Dapp Creator contract"
        );
        _;
    }

    // Modifier just accept call from dappCreator
    modifier onlyFromTreasury() {
        require(
            msg.sender == INZ_TREASURY,
            "Can only call from InZTreasury contract"
        );
        _;
    }

    modifier onlyFromValidNftCollection() {
        require(
            nftCollectionsList.contains(msg.sender),
            "Invalid NftCollection"
        );
        _;
    }

    constructor(address _nftFactory, address _dappCreator, address _treasury) {
        NFT_FACTORY = _nftFactory;
        DAPP_CREATOR = _dappCreator;
        INZ_TREASURY = _treasury;
    }

    function initialize() public initializer {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
    }

    /**
     *  @notice Function allows Factory to add new deployed collection
     */
    function InsertNewCollectionAddress(
        address _nftCollection
    ) external onlyFromFactory {
        nftCollectionsList.add(_nftCollection);
    }

    /**
     *      Config for each nftType of NFT collection
     */
    function configCollection(
        address _collectionAddress,
        uint8 _nftType,
        uint256 _price,
        uint256 _totalSupply,
        string memory _baseMetadataUri,
        address _creatorAddress,
        address _payToken
    ) external onlyFromFactory {
        require(
            nftCollectionsList.contains(_collectionAddress),
            "Invalid NFT collection address"
        );
        InZNFTTypeDetail.NFTTypeDetail memory _nftTypeNew;
        _nftTypeNew.nftType = _nftType;
        if (_totalSupply == 0) {
            _nftTypeNew.totalSupply = 2 ** 256 - 1; // max uint256
        } else {
            _nftTypeNew.totalSupply = _totalSupply;
        }
        _nftTypeNew.price = _price;
        nftTypeDetails[_collectionAddress][_nftType] = _nftTypeNew;
        uriNFTs[_collectionAddress] = _baseMetadataUri;
        creatorCollection[_collectionAddress] = _creatorAddress;
        payTokenCollection[_collectionAddress] = _payToken;
    }

    /**
     *      Set New Contract: Creator, Factory, Treasury
     */
    function updateConfigContract(
        address _nftFactory,
        address _dappCreator,
        address _treasury
    ) external onlyFromFactory {
        NFT_FACTORY = _nftFactory;
        DAPP_CREATOR = _dappCreator;
        INZ_TREASURY = _treasury;
    }

    function getCreatorCollection(
        address _collectionAddress
    ) external view onlyFromDappCreator returns (address) {
        return creatorCollection[_collectionAddress];
    }

    function getCreatorFromTreasury(
        address _collectionAddress
    ) external view onlyFromTreasury returns (address) {
        return creatorCollection[_collectionAddress];
    }

    function getPayTokenCollection(
        address _collectionAddress
    ) external view onlyFromDappCreator returns (address) {
        return payTokenCollection[_collectionAddress];
    }

    function updateCreatorCollection(
        address _newCreator,
        address _collectionAddress
    ) external onlyFromDappCreator {
        require(
            nftCollectionsList.contains(_collectionAddress),
            "Invalid NFT collection address"
        );
        creatorCollection[_collectionAddress] = _newCreator;
    }

    function updatePayTokenCollection(
        address _collectionAddress,
        address _payToken
    ) external onlyFromDappCreator {
        require(
            nftCollectionsList.contains(_collectionAddress),
            "Invalid NFT collection address"
        );
        payTokenCollection[_collectionAddress] = _payToken;
    }

    /**
     *      Config for each tokenURI() of collection
     */
    function configCollectionURI(
        address _collectionAddress,
        string memory _baseMetadataUri
    ) external onlyFromFactory {
        require(
            nftCollectionsList.contains(_collectionAddress),
            "Invalid NFT collection address"
        );
        uriNFTs[_collectionAddress] = _baseMetadataUri;
    }

    function getNftTypeDetail(
        address _collectionAddress,
        uint8 _tokenType
    ) external view returns (InZNFTTypeDetail.NFTTypeDetail memory) {
        return nftTypeDetails[_collectionAddress][_tokenType];
    }

    /**
     *      get tokenURI() of collection
     */
    function getCollectionURI(
        address _collectionAddress,
        uint256 _tokenId
    ) external view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    uriNFTs[_collectionAddress],
                    "/",
                    Strings.toHexString(
                        uint256(uint160(_collectionAddress)),
                        20
                    ),
                    "/",
                    Strings.toString(_tokenId),
                    ".json"
                )
            );
    }

    /**
     *  @notice Function allows Dapp Creator call to get collection price and address of payToken
     */
    function getCollectionPrice(
        address _nftCollection,
        uint8 _nftType
    ) external view returns (uint256, address) {
        return (
            nftTypeDetails[_nftCollection][_nftType].price,
            payTokenCollection[_nftCollection]
        );
    }

    /**
     *  @notice Function check the order attributes is valid or not in the current state of system
     *  @dev Function used for all contract call to for validations
     *  @param _nftCollection The address of the collection contract need to check
     *  @param _nftType The order need to check
     */
    function checkValidMintingAttributes(
        address _nftCollection,
        uint8 _nftType
    ) external view returns (bool) {
        return nftTypeDetails[_nftCollection][_nftType].totalSupply != 0;
    }

    /// Getters
    /**
     *  @notice function allows external to get DaapNFTCreator
     */
    function getNftCreator() external view returns (address) {
        return DAPP_CREATOR;
    }
}
