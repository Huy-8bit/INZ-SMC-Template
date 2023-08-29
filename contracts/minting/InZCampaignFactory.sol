// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./campaignNFT/InzCampaignTypesNFT1155.sol";
import "./campaignNFT/InzCampaignTypesNFT721.sol";
import "./campaignBOX/InZBoxCampaign.sol";
import "./libraries/InZNFTTypeDetail.sol";
import "./interfaces/IConfiguration.sol";

contract InZCampaignFactory is AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     *          Constant
     */
    uint8 internal constant STANDARD_ID_ERC721 = 1;
    uint8 internal constant STANDARD_ID_ERC1155 = 2;

    /**
     *          Event Definitions
     */
    event NewNFT(
        uint8 startdardId,
        address campaignAddress,
        address campaignPaymentAddress,
        InZNFTTypeDetail.NFTTypeDetail[] nftTypesDetail,
        IERC20 coinToken,
        string symbol,
        string name,
        address adminAddress
    );

    event NewBox(
        address newBoxAddress,
        string uri,
        address payToken,
        string name,
        string symbol,
        uint256 startTime,
        uint256 endTime,
        bool isAutoIncreaseId,
        uint256 totalSupply,
        uint256 price
    );

    event SetConfiguration(address newConfiguration);

    /**
     *          Storage data declarations
     */
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // InZCampaigns Address list
    address[] public inZNftCampaignsAddress;
    address[] public inZBoxCampaignsAddress;

    // marketplace address
    address public marketAddress;

    // implementAddress for NFT
    address public nftImplementationAddressERC721;
    address public nftImplementationAddressERC1155;

    // Mapping standardId to list campaign NFT address
    mapping(uint8 => address[]) internal standardIds;

    // List of NFT collections
    EnumerableSet.AddressSet private nftCollectionsList;

    // Mapping campaign NFT address to standardId
    mapping(address => uint8) internal standard;

    // implementation of BOX
    address public boxImplementationAddress;

    // Wrapper Creator address: using for calling from dapp
    address public dappCreatorAddress;

    // This contract config metadata for all collections
    IConfiguration public nftConfiguration;

    /**
     *          Contructor of the contract
     */
    constructor(IConfiguration _nftConfiguration) {
        nftConfiguration = _nftConfiguration;
        nftImplementationAddressERC721 = address(new InzCampaignTypesNFT721());
        nftImplementationAddressERC1155 = address(
            new InzCampaignTypesNFT1155()
        );
        boxImplementationAddress = address(new InZBoxCampaign());

        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * Create instance of InZCampaign;
     * @param _standardId support start ERC721 && ERC1155(1: ERC721, 2: ERC1155)
     * @param _campaignPaymentAddress payment address to receive coinToken when nft have sold
     * @param _coinToken currency that KOLs want to sell nft campaign
     * @param _symbol symbol of this campaign
     * @param _name name of this campaign
     * @param _nftTypesDetail nft type detail
     */
    function createCampaign(
        uint8 _standardId,
        address _campaignPaymentAddress,
        string memory _baseMetadataUri,
        IERC20 _coinToken,
        string memory _symbol,
        string memory _name,
        InZNFTTypeDetail.NFTTypeDetail[] memory _nftTypesDetail
    ) external onlyRole(ADMIN_ROLE) {
        require(
            _standardId == STANDARD_ID_ERC721 ||
                _standardId == STANDARD_ID_ERC1155,
            "standardId not support"
        );
        address campaign;
        if (_standardId == STANDARD_ID_ERC721) {
            // ERC721
            campaign = Clones.clone(nftImplementationAddressERC721);
            InzCampaignTypesNFT721(campaign).initialize(
                marketAddress,
                _campaignPaymentAddress,
                _coinToken,
                _symbol,
                _name,
                msg.sender,
                address(this)
            );
            standardIds[STANDARD_ID_ERC721].push(address(campaign));
            standard[address(campaign)] = STANDARD_ID_ERC721;

            // Call to config the default royalty fee rate
            // ICollection(campaign).configRoyalty(
            //     _treasuryAddress,
            //     _royaltyRate
            // );

            // Add new collection to configuration
            nftConfiguration.InsertNewCollectionAddress(campaign);
            nftCollectionsList.add(campaign);

            // Config prices
            for (uint i = 0; i < _nftTypesDetail.length; i++) {
                _configOneCollection(
                    campaign,
                    _nftTypesDetail[i].nftType,
                    _nftTypesDetail[i].price,
                    _nftTypesDetail[i].totalSupply,
                    _baseMetadataUri,
                    msg.sender,
                    address(_coinToken)
                );
            }
        } else {
            // ERC1155
            bool _isFixedTokenId = false;
            uint256 _nftTotalSupply = 1000;
            campaign = Clones.clone(nftImplementationAddressERC1155);
            InzCampaignTypesNFT1155(campaign).initialize(
                marketAddress,
                _baseMetadataUri,
                _campaignPaymentAddress,
                _isFixedTokenId,
                _coinToken,
                _symbol,
                _name,
                msg.sender,
                _nftTypesDetail,
                _nftTotalSupply
            );
            standardIds[STANDARD_ID_ERC1155].push(address(campaign));
            standard[address(campaign)] = STANDARD_ID_ERC1155;
        }

        inZNftCampaignsAddress.push(address(campaign));

        emit NewNFT(
            _standardId,
            address(campaign),
            _campaignPaymentAddress,
            _nftTypesDetail,
            _coinToken,
            _symbol,
            _name,
            msg.sender
        );
    }

    /**
     *  @notice Create Mystery Box
     *
     */
    function createBox(
        string memory _boxUri,
        IERC20 _payToken,
        string memory _name,
        string memory _symbol,
        uint256 _startTime,
        uint256 _endTime,
        bool _isAutoIncreaseId,
        uint256 _totalSupply,
        uint256 _price
    ) external onlyRole(ADMIN_ROLE) {
        address clone = Clones.clone(boxImplementationAddress);
        InZBoxCampaign(clone).initialize(
            _boxUri,
            _payToken,
            _name,
            _symbol,
            _startTime,
            _endTime,
            _isAutoIncreaseId,
            _totalSupply,
            _price
        );
        inZBoxCampaignsAddress.push(address(clone));
        emit NewBox(
            address(clone),
            _boxUri,
            address(_payToken),
            _name,
            _symbol,
            _startTime,
            _endTime,
            _isAutoIncreaseId,
            _totalSupply,
            _price
        );
    }

    /*
       @dev: Set new configuration
       @param {address} _address - This is address of new configuration
    */
    function setConfiguration(
        IConfiguration _nftConfiguration
    ) external onlyRole(ADMIN_ROLE) {
        require(
            address(_nftConfiguration) != address(0x0),
            "Address of configuration must be required."
        );
        nftConfiguration = _nftConfiguration;
        emit SetConfiguration(address(_nftConfiguration));
    }

    /**
     *      Config collection
     */
    function configCollection(
        address _collectionAddress,
        uint8 _nftType,
        uint256 _price,
        uint256 _totalSupply,
        string memory _baseMetadataUri,
        address _payToken
    ) external onlyRole(ADMIN_ROLE) {
        _configOneCollection(
            _collectionAddress,
            _nftType,
            _price,
            _totalSupply,
            _baseMetadataUri,
            msg.sender,
            _payToken
        );
    }

    function _configOneCollection(
        address _collectionAddress,
        uint8 _nftType,
        uint256 _price,
        uint256 _totalSupply,
        string memory _baseMetadataUri,
        address _creatorAddress,
        address _payToken
    ) internal {
        nftConfiguration.configCollection(
            _collectionAddress,
            _nftType,
            _price,
            _totalSupply,
            _baseMetadataUri,
            _creatorAddress,
            _payToken
        );
    }

    /**
     *      Config collection
     */
    function configNftCollectionURI(
        address _collectionAddress,
        string memory _baseMetadataUri
    ) external onlyRole(ADMIN_ROLE) {
        nftConfiguration.configCollectionURI(
            _collectionAddress,
            _baseMetadataUri
        );
    }

    function updateNftConfigContract(
        address _nftFactory,
        address _dappCreator,
        address _treasury
    ) external onlyRole(ADMIN_ROLE) {
        nftConfiguration.updateConfigContract(
            _nftFactory,
            _dappCreator,
            _treasury
        );
    }

    // function grantRoles(address _contract, )

    /**
     *              INHERITANCE FUNCTIONS
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     *              GETTERS
     */
    function getAllNFTCampaign()
        external
        view
        onlyRole(ADMIN_ROLE)
        returns (address[] memory)
    {
        return inZNftCampaignsAddress;
    }

    function getAllBoxCampaign()
        external
        view
        onlyRole(ADMIN_ROLE)
        returns (address[] memory)
    {
        return inZBoxCampaignsAddress;
    }

    /**
     *              Get list campaign NFT address by standardId
     */
    function getNFTCampaignsByStandardId(
        uint8 _standardId
    ) external view onlyRole(ADMIN_ROLE) returns (address[] memory) {
        return standardIds[_standardId];
    }

    /**
     *              Get standardId by campaign NFT address
     */
    function getStandardIdByCampaign(
        address _campaignAddress
    ) external view onlyRole(ADMIN_ROLE) returns (uint8) {
        return standard[_campaignAddress];
    }

    /// Getters
    function getCurrentDappCreatorAddress() external view returns (address) {
        return nftConfiguration.getNftCreator();
    }

    /**
     *  @notice Function allows to get the current Nft Configurations
     */
    function getCurrentConfiguration() external view returns (address) {
        return address(nftConfiguration);
    }

    function getCollectionAddress(
        uint256 index
    ) external view returns (address) {
        return nftCollectionsList.at(index);
    }

    function isValidNftCollection(
        address _nftCollection
    ) external view returns (bool) {
        return nftCollectionsList.contains(_nftCollection);
    }

    /**
     *              SETTERS
     */
}
