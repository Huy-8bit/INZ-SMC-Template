// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "../libraries/InZNFTTypeDetail.sol";
import "../interfaces/IInZNFTMarket.sol";
import "../utils/InterfaceFunction.sol";
import "../interfaces/IFactory.sol";
import "../interfaces/IConfiguration.sol";


contract InzCampaignTypesNFT721 is 
    ERC721Upgradeable, 
    AccessControlUpgradeable, 
    UUPSUpgradeable, 
    ERC721RoyaltyUpgradeable,
    OwnableUpgradeable
    
{
    /**
     *          External using
     */
    using InZNFTTypeDetail for InZNFTTypeDetail.NFTTypeDetail;
    using Counters for Counters.Counter;

    /**
     *          Event Definitions
     */
    event ActiveGiftCode(address to, uint256 tokenId, uint8 tokenType, string uri, string giftCode);
    event TokenCreated(address to, uint256 tokenId, uint256 tokenType);
    event AddNftType(uint8 tokenType, uint256 totalSupply, uint256 price);
    struct ReturnMintingOrder {
        uint256 nftType;
        uint256 tokenId;
    }
    event MintOrderForDev(
        bytes callbackData,
        address to,
        ReturnMintingOrder[] returnMintingOrder
    );
    event MintOrderFromDaapCreator(
        string callbackData,
        address to,
        ReturnMintingOrder[] returnMintingOrder
    );
    // /**
    //  *          Storage data declarations
    //  */
    bytes32 internal constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 internal constant DESIGN_ROLE = keccak256("DESIGN_ROLE");
    bytes32 internal constant BURNER_ROLE = keccak256("BURNER_ROLE");
    
    // Market place owner address to receive market fee when mint token
    address public marketOwnerAddress;
    // Base meta data uri 
    string public baseMetadataUri;
    // Campaign Payment Address to receive when mint token
    address public campaignPaymentAddress;

    // Start time to buy for whitelist
    uint256 public whitelistStartTime;
    // Start time to public buy on this campaign
    uint256 public publicStartTime;
    // End time to buy first nft on this campaign
    uint256 public endTimeToBuy;
    // Currency use to buy first nft of this campaign

    IERC20 public coinToken;
    
    // TokenID Counter
    Counters.Counter internal tokenIdCounter;
    // Mapping token type to supply have minted
    mapping (uint8 => uint256) public nftTypeSupply;
    // Mapping token's holder address to tokenIds list  
    mapping (address => uint256[]) public holders;
    // max allocation for normal user
    uint256 internal maxAllocation;
    // Mapping token id to token type
    mapping (uint256 => uint8) internal tokenIdsByType; 
    // Mapping from token ID to token details.
    // mapping(uint256 => InZNFTDetail.NFTDetail) public tokenDetails;

    // allow user call function mint when buyable is true
    bool public buyable;
    // Total whitelist pool
    uint256 public whiteListPool;
    // total whitelist have bought
    uint256 public whiteListBought;
    // mapping address to amount can buy
    mapping (address => uint256) public whitelistBuyable;
    // mapping tokenURI to type NFT
    mapping(uint8 => string) public uriByType;
    // mapping NFT creted from Factory
    address internal factoryAddress;
    /**
     * @notice Checks if the msg.sender is a contract or a proxy
     */
    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    modifier onlyFromDaapCreator() {
        require(
            msg.sender == getNftCreator(),
            "Not be called from Daap Creator"
        );
        _;
    }

    /**
     *          Contract Initialization
     */
    function initialize(
        address _marketOwnerAddress,
        address _campaignPaymentAddress,
        IERC20 _coinToken,
        string memory _symbol,
        string memory _name,
        address _adminAddress,
        address _factoryAddress
    ) external initializer {
        __ERC721_init(_name, _symbol);
        __AccessControl_init();
        __UUPSUpgradeable_init();
        _transferOwnership(_adminAddress);

        marketOwnerAddress = _marketOwnerAddress;
        campaignPaymentAddress = _campaignPaymentAddress;
        coinToken = _coinToken;
        buyable = false;
        factoryAddress = _factoryAddress;
        _setupRole(ADMIN_ROLE, _adminAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, _adminAddress);
        _setupRole(DESIGN_ROLE, _adminAddress);
        _setupRole(BURNER_ROLE, _adminAddress);
    }

    // Get NFT IDs by owner
    function getNftIdsByOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory ids = holders[_owner];
        return ids;
    }

    /**
    * @dev                  Owner mint without transfer TOKEN
    * @param _amount        Amount the user wants to mint
    * @param _tokenType     Type of token to mint
    * @param _to            Transfer NTF to address _to
    */
    function ownerMint(uint256 _amount, uint8 _tokenType, address _to) external onlyRole(DESIGN_ROLE) {
        require(_amount > 0, "No token to mint");
        // Check token type is exist in this campaign
        InZNFTTypeDetail.NFTTypeDetail memory nftTypeDetail = IConfiguration(getNftConfigurations()).getNftTypeDetail(address(this), _tokenType);
        require(nftTypeDetail.totalSupply > 0, "Token type does not exist");
        // Check token type supply 
        uint256 nftTypeHaveMinted = nftTypeSupply[_tokenType];
        uint256 _amountNftTypeCurrent = nftTypeHaveMinted + _amount;
        require(nftTypeDetail.totalSupply >= _amountNftTypeCurrent, "NFT type sold out");
        nftTypeSupply[_tokenType] = _amountNftTypeCurrent;
        if (_to == address(0)) { // if address is 0x
            _to = msg.sender;
        }
        for (uint256 i = 0; i < _amount; ++i) {
            uint256 _id = tokenIdCounter.current();
            tokenIdCounter.increment();
            _safeMint(_to, _id);
            // Update user bought list
            holders[_to].push(_id);
            // Update token id by type
            tokenIdsByType[_id] = _tokenType;
            emit TokenCreated(_to, _id, _tokenType);
        }
    }

    /**
    * @dev              Mint tokens for id defined (first buy on market)
    * @param _amount    Amount the user wants to mint
    * @param _tokenType Type of token to mint
    * @param _to        Address receive NFT
    */
    function mint(
        uint256 _amount, 
        uint8 _tokenType, 
        address _to,
        string calldata _callbackData
    ) external onlyFromDaapCreator {
        // require(buyable == true, "Mint NFT have not start yet");
        // address _buyer = msg.sender;
        // Check time to buy
        // require(block.timestamp >= publicStartTime, "It's not time to buy public sale");
        // require(block.timestamp <= endTimeToBuy, "It's not time to buy");
        // Check max allocation user can buy
        // if (maxAllocation > 0) {
        //     require(holders[_to].length < maxAllocation, "Buy limit reached");
        // }
        // Check token type is exist in this campaign
        InZNFTTypeDetail.NFTTypeDetail memory nftTypeDetail = IConfiguration(getNftConfigurations()).getNftTypeDetail(address(this), _tokenType);
        require(nftTypeDetail.totalSupply > 0, "Token type does not exist");
        // Check token type supply 
        uint256 nftTypeHaveMinted = nftTypeSupply[_tokenType];
        uint256 _amountNftTypeCurrent = nftTypeHaveMinted + _amount;
        require(nftTypeDetail.totalSupply >= _amountNftTypeCurrent, "NFT type sold out");
        nftTypeSupply[_tokenType] = _amountNftTypeCurrent;
        ReturnMintingOrder[] memory _returnOrder = new ReturnMintingOrder[](_amount);
        for (uint256 i = 0; i < _amount; ++i) {
            uint256 _id = tokenIdCounter.current();
            tokenIdCounter.increment();
            _safeMint(_to, _id);
            // Update user bought list
            holders[_to].push(_id);
            // Update token id by type
            tokenIdsByType[_id] = _tokenType;
            emit TokenCreated(_to, _id, _tokenType);
            _returnOrder[i] = ReturnMintingOrder(_id, _tokenType);
        }

        emit MintOrderFromDaapCreator(_callbackData, _to, _returnOrder);
    }

    /**
    * @dev                  Address in whitelist Mint tokens for id defined (first buy on market)
    * @param _amount        Id to mint
    * @param _tokenType     Type of token to mint - if tokenType is 0
    * @param _to            Address receive NFT
    */
    function whitelistMint(
        uint256 _amount, 
        uint8 _tokenType, 
        address _to
    ) external {
        address _buyer = msg.sender;
        require(whitelistBuyable[_to] >= _amount, "User not in whitelist or limit reached");
        // Check time to buy
        require(block.timestamp >= publicStartTime, "It's not time to buy public sale");
        require(block.timestamp <= endTimeToBuy, "It's not time to buy");
        // Check max allocation user can buy
        if (maxAllocation > 0) {
            require(holders[_to].length < maxAllocation, "Buy limit reached");
        }
        // Check token type is exist in this campaign
        InZNFTTypeDetail.NFTTypeDetail memory nftTypeDetail = IConfiguration(getNftConfigurations()).getNftTypeDetail(address(this), _tokenType);
        require(nftTypeDetail.totalSupply > 0, "Token type does not exist");
        // Check token type supply 
        uint256 nftTypeHaveMinted = nftTypeSupply[_tokenType];
        uint256 _amountNftTypeCurrent = nftTypeHaveMinted + _amount;
        require(nftTypeDetail.totalSupply >= _amountNftTypeCurrent, "NFT type sold out");
        uint256 _amount_price = nftTypeDetail.price * _amount;
        require(_amount_price <= coinToken.balanceOf(_buyer), "User need hold enough Token to buy this nft");
        coinToken.transferFrom(_buyer, campaignPaymentAddress, _amount_price);
        // update data whitelist
        whitelistBuyable[_to] -= _amount;
        whiteListBought += _amount;
        // Update nft type supply have minted
        nftTypeSupply[_tokenType] = _amountNftTypeCurrent;
        
        for (uint256 i = 0; i < _amount; ++i) {
            uint256 _id = tokenIdCounter.current();
            tokenIdCounter.increment();
            _safeMint(_to, _id);
            // Update user bought list
            holders[_to].push(_id);
            // Update token id by type
            tokenIdsByType[_id] = _tokenType;
            emit TokenCreated(_to, _id, _tokenType);
        }
    }

    /**
     *      Function return tokenURI for specific NFT
     *      @param _tokenId ID of NFT
     *      @return tokenURI of token with ID = _tokenId
     */
    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        return IConfiguration(getNftConfigurations()).getCollectionURI(address(this), _tokenId);
    }

    /**
     *      Function that gets latest ID of this NFT contract
     *      @return tokenId of latest NFT
     */
    function lastId() public view returns (uint256) {
        return tokenIdCounter.current();
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

    /** Marketplace fee */
    function _marketFee(uint256 _amount) internal view returns (uint256 fee) {
        // TODO check rate
        uint256 marketFeePercent = IInZNFTMarket(marketOwnerAddress).getMarketFeePercent(address(this));
        fee = (_amount / 10000) * marketFeePercent;
    }

    function withdraw() external  onlyRole(DEFAULT_ADMIN_ROLE) {
        coinToken.transfer(msg.sender, coinToken.balanceOf(address(this)));
    }

    /** Burns a list  nft ids. */
    function burn(uint256[] memory ids) external onlyRole(BURNER_ROLE) {
        for (uint256 i = 0; i < ids.length; ++i) {
            _burn(ids[i]);
        }
    }

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

    // set whitelist address with amount can buy
    function setWhitelistsBuyable(
        address[] memory _whitelistAddresses, 
        uint256[] memory _buyableAmountList
    ) external onlyRole(ADMIN_ROLE) {
        require(
            _whitelistAddresses.length == _buyableAmountList.length, 
            "Whitelist and buyable amount list must be same length"
        );
        for (uint256 i = 0; i < _whitelistAddresses.length; i++) {
            whitelistBuyable[_whitelistAddresses[i]] = _buyableAmountList[i];
            whiteListPool += _buyableAmountList[i];
        }
    }

    /** Enable common user mint NFT */
    function setBuyable(bool _isBuyable) external onlyRole(DESIGN_ROLE) {
        buyable = _isBuyable;
    }

    /**
     * @dev Function allows ADMIN ROLE to config the default royalty fee
     */
    function configRoyalty(
        address _wallet,
        uint96 _rate
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        super._setDefaultRoyalty(_wallet, _rate);
    }

    /**
     *      INHERITANCE FUNCTIONS
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(
            ERC721Upgradeable,
            AccessControlUpgradeable,
            ERC721RoyaltyUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721RoyaltyUpgradeable) {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

    /**
     *          INTERNAL FUNCTION
     */
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(ADMIN_ROLE)
    {}


    /**
     *  @notice Function internal getting the address of NFT creator
     */
    function getNftCreator() internal view returns (address) {
        return IFactory(factoryAddress).getCurrentDappCreatorAddress();
    }

    /**
     *  @notice Function internal returns the address of NftConfigurations
     */
    function getNftConfigurations() internal view returns (address) {
        return IFactory(factoryAddress).getCurrentConfiguration();
    }

    /**
     *  @notice Function get factory address
     */
    function getFactoryAddress() external view onlyRole(ADMIN_ROLE) returns (address) {
        return factoryAddress;
    }

    /**
     *  @notice Function get factory address
     */
    function getConfigNFT(uint8 _tokenType) 
    external view onlyRole(ADMIN_ROLE) 
    returns (InZNFTTypeDetail.NFTTypeDetail memory) {
        return IConfiguration(getNftConfigurations()).getNftTypeDetail(address(this), _tokenType);
    }
    
    /**
     * @notice Checks if address is a contract
     * @dev It prevents contract from being targetted
     */
    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}
