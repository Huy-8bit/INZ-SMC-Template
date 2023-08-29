// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/InZNFTDetail.sol";
import "../libraries/InZNFTTypeDetail.sol";
import "../interfaces/INFTOpeningItem.sol";
import "../interfaces/IInZNFTMarket.sol";
import "../utils/InterfaceFunction.sol";

contract InZBoxCampaign is
    ERC721Upgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    ///
    ///             EXTERNAL USING
    ///
    using Counters for Counters.Counter;

    ///
    ///             STRUCTS DEFINITION

    ///
    ///             EVENTS DEFINATION
    ///
    event BoxBought(address buyer, uint256 tokenId);

    event SetNewPayToken(address oldToken, address newToken);

    event SetNewNftOpeningItem(address oldAddress, address newAddress);

    event OpenBox(address owner, uint256 tokenId);

    ///
    ///             STORAGE DATA DECLARATIONS
    ///
    bytes32 internal constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 internal constant DESIGNER_ROLE = keccak256("DESIGNER_ROLE");
    bytes32 internal constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");

    // Pay Token for minting action
    IERC20 public s_payToken;

    // tokenURI of box
    string private s_tokenUri;

    // Counter for tokenId
    Counters.Counter internal s_tokenIdCounter;

    // Item that can be opened via opeing boxes
    INFTOpeningItem public s_nftOpeningItem;

    // Mapping tokenId to BoxDetail
    mapping(address => uint256[]) private s_boxesOwner;

    // Mapping tokenId and status of opened or not
    mapping(uint256 => bool) private isOpened;

    // OPTION: Fixed, auto-increase tokenId or not
    bool private s_isAutoIncreaseId;

    // Total supply of Box campaign
    uint256 private s_totalSupply;

    // Price of the box
    uint256 private s_price;

    // Total box was minted
    uint256 private s_totalMinted;

    // Duration of the campaign
    uint256 private s_startTimeToBuy;
    uint256 private s_endTimeToBuy;

    ///
    ///             MODIFIER
    ///
    modifier isApproveEnough(
        IERC20 token,
        address owner,
        address spender,
        uint256 checkingAmount
    ) {
        require(
            token.allowance(owner, spender) >= checkingAmount,
            "Not approve enough token"
        );
        _;
    }

    modifier isValidTimeToMint() {
        require(
            block.timestamp >= s_startTimeToBuy,
            "The campain's not started yet"
        );
        require(
            block.timestamp <= s_endTimeToBuy,
            "The campaign's already ended"
        );
        _;
    }

    modifier isUnreachLimit() {
        require(s_totalMinted < s_totalSupply, "Sold out");
        _;
    }

    function initialize(
        string memory _uri,
        IERC20 _payToken,
        string memory _name,
        string memory _symbol,
        uint256 _startTimeToBuy,
        uint256 _endTimeToBuy,
        bool _isAutoIncreaseId,
        uint256 _totalSupply,
        uint256 _price
    ) external initializer {
        s_payToken = _payToken;
        s_tokenUri = _uri;
        s_startTimeToBuy = _startTimeToBuy;
        s_endTimeToBuy = _endTimeToBuy;
        s_isAutoIncreaseId = _isAutoIncreaseId;
        s_totalSupply = _totalSupply;
        s_price = _price;

        __ERC721_init(_name, _symbol);
        __AccessControl_init();
        __UUPSUpgradeable_init();
        _transferOwnership(tx.origin);

        _setupRole(DEFAULT_ADMIN_ROLE, tx.origin);
        _setupRole(ADMIN_ROLE, tx.origin);
        _setupRole(DESIGNER_ROLE, tx.origin);
        _setupRole(WITHDRAW_ROLE, tx.origin);
    }

    function mint(
        uint256 tokenId
    )
        external
        isApproveEnough(s_payToken, msg.sender, address(this), s_price)
        isValidTimeToMint
        isUnreachLimit
    {
        uint256 _executeId;
        if (!s_isAutoIncreaseId) {
            require(!_exists(tokenId), "Mint Box: tokenId's already existed");
            _executeId = tokenId;
        } else {
            s_tokenIdCounter.increment();
            _executeId = s_tokenIdCounter.current();
        }

        // Transfer token from buyer to campagin
        s_payToken.transferFrom(msg.sender, address(this), s_price);

        // Mint box for buyer
        _mint(msg.sender, _executeId);

        // Update state
        s_totalMinted += 1;
        s_boxesOwner[msg.sender].push(_executeId);
        isOpened[_executeId] = false;

        emit BoxBought(msg.sender, _executeId);
    }

    function openBox(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "You did not owned the token");
        require(!isOpened[tokenId], "Box's already opened");

        // Call NFT Opening Item to open box
        s_nftOpeningItem.mintFromBoxOpening(msg.sender);

        // Save state
        isOpened[tokenId] = true;
        emit OpenBox(msg.sender, tokenId);
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
    ) external onlyRole(ADMIN_ROLE) // returns (uint256)
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
    ) external onlyRole(ADMIN_ROLE) {
        InterfaceFunction.execTx(to, value, txGas, data, operation);
    }

    ///
    ///         SETTERS
    ///
    function setNftOpeningItem(
        INFTOpeningItem _openingItem
    ) external onlyRole(DESIGNER_ROLE) {
        require(
            _openingItem != s_nftOpeningItem,
            "Set New NFT Opening Item: The new one must be different from the old one"
        );
        address oldAddress = address(s_nftOpeningItem);
        s_nftOpeningItem = _openingItem;
        emit SetNewNftOpeningItem(oldAddress, address(s_nftOpeningItem));
    }

    function setPayToken(IERC20 _newPayToken) external onlyRole(DESIGNER_ROLE) {
        require(
            _newPayToken != s_payToken,
            "Set New Pay Token: The new one must be different from the old one"
        );
        address oldPayToken = address(s_payToken);
        s_payToken = _newPayToken;
        emit SetNewPayToken(oldPayToken, address(s_nftOpeningItem));
    }

    ///
    ///         GETTERS
    ///
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        return s_tokenUri;
    }

    function getListBoxOf(
        address owner
    ) external view returns (uint256[] memory) {
        return s_boxesOwner[owner];
    }

    ///
    ///          INHERITANCE FUNCTIONS
    ///
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(ADMIN_ROLE) {}

    ///
    ///         INTERNAL FUNCTIONS
    ///
}
