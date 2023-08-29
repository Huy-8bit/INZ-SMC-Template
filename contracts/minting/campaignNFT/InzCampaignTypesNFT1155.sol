// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../libraries/InZNFTDetail.sol";
import "../libraries/InZNFTTypeDetail.sol";
import "../interfaces/IInZNFTMarket.sol";
import "../utils/InterfaceFunction.sol";
import "../interfaces/ICampaignNFT1155.sol";


contract InzCampaignTypesNFT1155 is
    ERC1155Upgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    OwnableUpgradeable
{

    /**
     *          External using
     */
    using InZNFTDetail for InZNFTDetail.NFTDetail;
    using InZNFTTypeDetail for InZNFTTypeDetail.NFTTypeDetail;
    using Counters for Counters.Counter;

    /**
     *          Event Definitions
     */
    event ActiveGiftCode(address to, uint256 tokenId, uint8 tokenType, string uri, string giftCode);
    event Mint(address to, uint256 tokenId, uint8 tokenType, string uri, uint256 kolProfit, uint256 marketFee);
    event AddNftType(uint8 tokenType, uint256 totalSupply, uint256 price);

    /**
     *          Storage data declarations
     */
    bytes32 internal constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 internal constant DESIGN_ROLE = keccak256("DESIGN_ROLE");
    bytes32 internal constant BURNER_ROLE = keccak256("BURNER_ROLE");
    
    // Market place owner address to receive market fee when mint token
    address internal marketOwnerAddress;

    // Base meta data uri 
    string internal baseMetadataUri;

    // Campaign Payment Address to receive when mint token
    address internal campaignPaymentAddress;

    // If true tokenId will set by minner
    bool internal isFixedTokenId;

    bool internal isInitNftType;

    // Start time to buy for whitelist
    uint256 internal whitelistStartTime;
    // Start time to public buy on this campaign
    uint256 internal publicStartTime;
    // End time to buy first nft on this campaign
    uint256 internal endTimeToBuy;

    // mapping type NFT => NFTTypeDetail Info
    uint8 public maxNFTType;

    // Currency use to buy first nft of this campaign
    IERC20 public coinToken;

    // symbol of this campaign
    string public symbol;

    // name of this campaign
    string public name;

    Counters.Counter internal tokenIdCounter;
    Counters.Counter internal typeCounter;

    // custom token Ids list
    mapping (uint256 => bool) internal customTokenIdsWhiteList;

    // Mapping token type to campaign detail on this campaign
    mapping (uint8 => InZNFTTypeDetail.NFTTypeDetail) internal nftTypeDetails;

    // Mapping token type to supply have minted
    mapping (uint8 => uint256) internal nftTypeSupply;

    // Mapping token's holder address to tokenIds list  
    mapping (address => uint256[]) internal holders;

    // max allocation for normal user
    uint256 internal maxAllocation;

    // Mapping token id to token type
    mapping (uint256 => uint8) internal tokenIdsByType; 

    // Mapping from token ID to token details.
    mapping(uint256 => InZNFTDetail.NFTDetail) public tokenDetails;

    // Mapping gift code is active
    mapping (string => bool) internal giftCodes;

    // mapping white list address to amount can buy
    mapping (address => uint256) internal whitelistBuyable;

    // total whitelist have bought
    uint256 public whitelistRoundBought;

    
    // mapping tokenURI to type NFT
    mapping(uint8 => string) public uriByType;

    /**
     *          Contract Initialization
     */
    function initialize(
        address _marketOwnerAddress,
        string memory _baseMetadataUri,
        address _campaignPaymentAddress,
        bool _isFixedTokenId, 
        IERC20 _coinToken,
        string memory _symbol,
        string memory _name,
        address _adminAddress,
        InZNFTTypeDetail.NFTTypeDetail[] memory _nftTypesDetail,
        uint256 _nftTotalSupply
    ) external initializer {
        __ERC1155_init("");
        __AccessControl_init();
        __UUPSUpgradeable_init();
        _transferOwnership(_adminAddress);
 
        uint256 _totalSupplyPerNftType;
        for (uint256 i = 0; i < _nftTypesDetail.length; ++i) {
            _totalSupplyPerNftType +=  _nftTypesDetail[i].totalSupply;
        }
        require(_totalSupplyPerNftType == _nftTotalSupply, "Total supply does not match");
        for (uint256 i = 0; i < _nftTypesDetail.length; ++i) {
            InZNFTTypeDetail.NFTTypeDetail memory _nftTypeNew;
            _nftTypeNew.price = _nftTypesDetail[i].price;
            _nftTypeNew.totalSupply = _nftTypesDetail[i].totalSupply;
            nftTypeDetails[_nftTypesDetail[i].nftType] = _nftTypeNew;
            emit AddNftType(
                _nftTypesDetail[i].nftType, 
                _nftTypesDetail[i].totalSupply, 
                _nftTypesDetail[i].price
            );
        }

        marketOwnerAddress = _marketOwnerAddress;
        baseMetadataUri = _baseMetadataUri;
        campaignPaymentAddress = _campaignPaymentAddress;
        isFixedTokenId = _isFixedTokenId;
        coinToken = _coinToken;
        symbol = _symbol;
        name = _name;

        _setupRole(ADMIN_ROLE, _adminAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, _adminAddress);
        _setupRole(DESIGN_ROLE, _adminAddress);
        _setupRole(BURNER_ROLE, _adminAddress);
    }
    

    // /**
    //  *      Function return tokenURI for specific NFT
    //  *      @param _tokenId ID of NFT
    //  *      @return uri of token with ID = _tokenId
    //  */
    // function uri(uint256 _tokenId) override public view returns (string memory) {
    //     return(tokenDetails[_tokenId].uri);
    // }


    // Get all nft by owner
    function getNftByOwner(address _owner) external view returns (InZNFTDetail.NFTDetail[] memory) {
        InZNFTDetail.NFTDetail[] memory nfts = new InZNFTDetail.NFTDetail[](holders[_owner].length);
        for (uint256 i = 0; i < holders[_owner].length; ++i) {
            uint256 amountOfIdUserOwner = balanceOf(_owner, holders[_owner][i]);
            if (amountOfIdUserOwner <= 0) continue;

            nfts[i] = tokenDetails[holders[_owner][i]];
        }
        return nfts;
    }

    /** Get token type info */
    function getNFTTypeInfo(uint8 _tokenType) external view returns (uint256 _totalSupply, uint256 _mintedSupply, uint256 _pricePerItem) {
        InZNFTTypeDetail.NFTTypeDetail memory typeDetail = nftTypeDetails[_tokenType];
        _totalSupply = typeDetail.totalSupply;
        _pricePerItem = typeDetail.price;
        _mintedSupply = nftTypeSupply[_tokenType];

        return (_totalSupply, _mintedSupply, _pricePerItem);
    }

    /**
     *          SETTERS
     */
    function setMaxAllocation(uint256 _maxAllocation) external onlyRole(DESIGN_ROLE) {
        maxAllocation = _maxAllocation;
    }

    function setCampaignPaymentAddress(address _campaignPaymentAddress) external onlyRole(DESIGN_ROLE) {
        campaignPaymentAddress = _campaignPaymentAddress;
    }

    function setWhiteListStartTime(uint256 _whitelistStartTime) external onlyRole(DESIGN_ROLE) {
        whitelistStartTime = _whitelistStartTime;
    }

    function setPublicStartTime(uint256 _publicStartTime) external onlyRole(DESIGN_ROLE) {
        publicStartTime = _publicStartTime;
    }

    function setEndTimeToBuy(uint256 _endTimeToBuy) external onlyRole(DESIGN_ROLE) {
        endTimeToBuy = _endTimeToBuy;
    }

    function setCoinToken(IERC20 _coinToken) external onlyRole(DESIGN_ROLE) {
        coinToken = _coinToken;
    }

    function customTokenIdToWhiteList(uint256 _tokenId, bool _isActive) external onlyRole(DESIGN_ROLE) {
        customTokenIdsWhiteList[_tokenId] = _isActive;
    }

    function tokenIdIsInWhiteList(uint256 _tokenId) external view onlyRole(DESIGN_ROLE) returns(bool) {
        return customTokenIdsWhiteList[_tokenId];
    }


    function withdraw() external  onlyRole(DEFAULT_ADMIN_ROLE) {
        coinToken.transfer(msg.sender, coinToken.balanceOf(address(this)));
    }

    // set whitelist address with amount can buy
    function setWhitelistBuyable(address[] memory _whitelistAddresses, uint256[] memory _buyableAmountList) external onlyRole(ADMIN_ROLE) {
        require(_whitelistAddresses.length == _buyableAmountList.length, "Whitelist and buyable amount list must be same length");
        for (uint256 i = 0; i < _whitelistAddresses.length; i++) {
            whitelistBuyable[_whitelistAddresses[i]] = _buyableAmountList[i];
        }
    }

    /**
    * @dev Mint tokens for id defined (first buy on market)
    * @param _tokenId       Id to mint
    * @param _tokenType     Type of token to mint - if tokenType is 0
    * @param _to            Address receive NFT
    */
    function mint(
        uint256 _tokenId, 
        uint8 _tokenType,
        address _to
    ) external  {
        address _buyer = msg.sender;
        // Check time to buy
        require(block.timestamp >= publicStartTime, "It's not time to buy public sale");
        require(block.timestamp <= endTimeToBuy, "It's not time to buy");

        // Check max allocation user can buy
        if (maxAllocation > 0) {
            require(holders[_to].length < maxAllocation, "Buy limit reached");
        }
        
        // Check token type is exist in this campaign
        InZNFTTypeDetail.NFTTypeDetail memory nftTypeDetail = nftTypeDetails[_tokenType];
        require(nftTypeDetail.totalSupply > 0, "Token type does not exist");
        
        // Check token type supply
        uint256 nftTypeHaveMinted = nftTypeSupply[_tokenType];
        require(nftTypeDetail.totalSupply > nftTypeHaveMinted, "Token run out");

        // If not fixed token id, id is auto increment
        if (!isFixedTokenId) {
            tokenIdCounter.increment();
            _tokenId = tokenIdCounter.current();
        } else {
            // require custom token id in white list
            require(_isCustomTokenIdExist(_tokenId), "Token id isn't in whitelist");
        }

        // Check token id is minted
        InZNFTDetail.NFTDetail memory tokenDetail = tokenDetails[_tokenId];
        require(tokenDetail.quantity == 0, "Token id is minted");

        uint256 marketPlaceFee = _marketFee(nftTypeDetail.price);

        require(nftTypeDetail.price <= coinToken.balanceOf(_to), "User need hold enough Token to buy this nft");

        // Fee for market
        coinToken.transferFrom(_buyer, marketOwnerAddress, marketPlaceFee);
        // Profit for the kol (total price - marketPlaceFee - discountFee)
        uint256 kolProfit = nftTypeDetail.price - marketPlaceFee;
        coinToken.transferFrom(_buyer, campaignPaymentAddress, kolProfit);

        // _setTokenUri(_tokenId, nftTypeDetail.cid);
        _mint(_to, _tokenId, 1, "");
        
        // Update user bought list
        holders[_to].push(_tokenId);
        
        // Update nft type supply have minted
        nftTypeSupply[_tokenType] = nftTypeHaveMinted + 1;

        // Update token id by type
        tokenIdsByType[_tokenId] = _tokenType;

        string memory metaDataUri = uri(_tokenId);

        // Update list token id in campaign
        tokenDetail.tokenId = _tokenId;
        tokenDetail.tokenType = _tokenType;
        tokenDetail.quantity = 1;
        // tokenDetail.uri = metaDataUri;
        tokenDetail.isOpened = _tokenType > 0;
        tokenDetail.owner = _to;

        tokenDetails[_tokenId] = tokenDetail;

        emit Mint(_to, _tokenId, _tokenType, metaDataUri, kolProfit, marketPlaceFee);
    }

    /**
      * @dev Mint token for user have gift code
    * @param _to                 The address to mint token to (dev Wallet)
    * @param _tokenId            Id to mint
    * @param _tokenType          Token type to mint
    * should update access control only dev or owner can call this function
    */
    function mintByGiftCode(
        address _to,
        uint256 _tokenId, 
        uint8 _tokenType, 
        string memory _giftCode
        ) 
            external
            onlyRole(ADMIN_ROLE) 
            returns (uint256)
        {
        // Check time to buy
        require(block.timestamp >= publicStartTime, "It's not time to buy public sale");
        require(block.timestamp <= endTimeToBuy, "It's not time to buy");

        // Check giftCode is activated
        require(!giftCodes[_giftCode], "Gift code is already activated");
        
        // Check token type is exist in this campaign
        InZNFTTypeDetail.NFTTypeDetail memory nftTypeDetail = nftTypeDetails[_tokenType];
        require(nftTypeDetail.totalSupply > 0, "Token type does not exist");
        
        // Check token type supply
        uint256 nftTypeHaveMinted = nftTypeSupply[_tokenType];
        require(nftTypeDetail.totalSupply > nftTypeHaveMinted, "Token run out");

        // If not fixed token id, id is auto increment
        if (!isFixedTokenId) {
            tokenIdCounter.increment();
            _tokenId = tokenIdCounter.current();
        } else {
            // require custom token id in white list
            require(_isCustomTokenIdExist(_tokenId), "Token id isn't in whitelist");
        }

        // Check token id is minted
        InZNFTDetail.NFTDetail memory tokenDetail = tokenDetails[_tokenId];
        require(tokenDetail.quantity == 0, "Token id is minted");
        // _setTokenUri(_tokenId, nftTypeDetail.cid);
        _mint(_to, _tokenId, 1, "");

        // Update user bought amount
        holders[_to].push(_tokenId);
        
        // Update nft type supply have minted
        nftTypeSupply[_tokenType] = nftTypeHaveMinted + 1;

        // Update token id by type
        tokenIdsByType[_tokenId] = _tokenType;

        string memory metaDataUri = uri(_tokenId);

        // Update list token id in campaign
        tokenDetail.tokenId = _tokenId;
        tokenDetail.tokenType = _tokenType;
        tokenDetail.quantity = 1;
        // tokenDetail.uri = metaDataUri;
        tokenDetail.isOpened = _tokenType > 0;
        tokenDetail.owner = _to;

        tokenDetails[_tokenId] = tokenDetail;
        giftCodes[_giftCode] = true;

        emit ActiveGiftCode(_to, _tokenId, _tokenType, metaDataUri, _giftCode);
        emit Mint(_to, _tokenId, _tokenType, metaDataUri, 0, 0);

        return _tokenId;
    }

    /**
    * @dev Address in whitelist Mint tokens for id defined (first buy on market)
    * @param _tokenId       Id to mint
    * @param _tokenType     Type of token to mint - if tokenType is 0
    * @param _to            Address receive NFT
    */
    function whitelistMint(
        uint256 _tokenId, 
        uint8 _tokenType,
        address _to
    ) external  {
        address _buyer = msg.sender;
        // Check time to buy
        require(block.timestamp >= whitelistStartTime, "It's not time to buy whitelist sale");
        require(block.timestamp <= endTimeToBuy, "It's not time to buy");

        // Check whitelist can mint
        require(whitelistBuyable[_to] > 0, "User not in whitelist or limit reached");
        
        // Check token type is exist in this campaign
        InZNFTTypeDetail.NFTTypeDetail memory nftTypeDetail = nftTypeDetails[_tokenType];
        require(nftTypeDetail.totalSupply > 0, "Token type does not exist");
        
        // Check token type supply
        uint256 nftTypeHaveMinted = nftTypeSupply[_tokenType];
        require(nftTypeDetail.totalSupply > nftTypeHaveMinted, "Token run out");

        // If not fixed token id, id is auto increment
        if (!isFixedTokenId) {
            tokenIdCounter.increment();
            _tokenId = tokenIdCounter.current();
        } else {
            // require custom token id in white list
            require(_isCustomTokenIdExist(_tokenId), "Token id isn't in whitelist");
        }

        // Check token id is minted
        InZNFTDetail.NFTDetail memory tokenDetail = tokenDetails[_tokenId];
        require(tokenDetail.quantity == 0, "Token id is minted");

        uint256 marketPlaceFee = _marketFee(nftTypeDetail.price);

        require(nftTypeDetail.price <= coinToken.balanceOf(_buyer), "User need hold enough Token to buy this nft");

        // Fee for market
        coinToken.transferFrom(_buyer, marketOwnerAddress, marketPlaceFee);
        // Profit for the kol (total price - marketPlaceFee - discountFee)
        uint256 kolProfit = nftTypeDetail.price - marketPlaceFee;
        coinToken.transferFrom(_buyer, campaignPaymentAddress, kolProfit);

        // _setTokenUri(_tokenId, nftTypeDetail.cid);
        _mint(_to, _tokenId, 1, "");

        // Update user bought amount
        holders[_to].push(_tokenId);

        // update whitelistBought and whitelistRoundBought
        whitelistRoundBought += 1;
        whitelistBuyable[_to] -= 1;
        
        // Update nft type supply have minted
        nftTypeSupply[_tokenType] = nftTypeHaveMinted + 1;

        // Update token id by type
        tokenIdsByType[_tokenId] = _tokenType;

        string memory metaDataUri = uri(_tokenId);

        // Update list token id in campaign
        tokenDetail.tokenId = _tokenId;
        tokenDetail.tokenType = _tokenType;
        tokenDetail.quantity = 1;
        // tokenDetail.uri = metaDataUri;
        tokenDetail.isOpened = _tokenType > 0;
        tokenDetail.owner = _to;

        tokenDetails[_tokenId] = tokenDetail;

        emit Mint(_to, _tokenId, _tokenType, metaDataUri, kolProfit, marketPlaceFee);
    }

    /**
     *  @notice     This function is only used for estimation purpose, therefore the call will always revert and encode the result in the revert data.
     *  @dev        This function's used for estimate gas for a execution call
     *  @param to           The address of caller
     *  @param value        The value of msg.value
     *  @param data         The data sent with tx
     *  @param operation    the operation of tx
     */
    function requiredTxGas(
        address to,
        uint256 value,
        bytes calldata data,
        InterfaceFunction.Operation operation
    ) 
        external
        onlyRole(ADMIN_ROLE)
        // returns (uint256)
    {
        InterfaceFunction.requiredTxGas(to, value, data, operation);
    }

    /**
     * This function allow ADMIN can execute a function witj specificed logic and params flexibily
     * @param to The caller of tx
     * @param value The msg.value of tx
     * @param txGas The estimated gas using for the tx
     * @param data The data comming with the tx
     * @param operation The operation of tx
     */
    function execTx(
        address to,
        uint256 value,
        uint256 txGas,
        bytes calldata data,
        InterfaceFunction.Operation operation
    ) 
        external 
        onlyRole(ADMIN_ROLE) 
    {
        InterfaceFunction.execTx(to, value, txGas, data, operation);
    }

    /**
     *      INHERITANCE FUNCTIONS
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC1155Upgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     *          INTERNAL FUNCTION
     */
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(ADMIN_ROLE)
    {}

    /** Marketplace fee */
    function _marketFee(uint256 _amount) internal view returns (uint256 fee) {
        // TODO check rate
        uint256 marketFeePercent = IInZNFTMarket(marketOwnerAddress).getMarketFeePercent(address(this));
        fee = (_amount / 10000) * marketFeePercent;
    }

    function _isCustomTokenIdExist(uint256 _tokenId) internal view returns (bool) {
        return customTokenIdsWhiteList[_tokenId];
    }
}
